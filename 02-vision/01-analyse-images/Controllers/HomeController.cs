using ImageWebApp.Models;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.AI.Vision.Common;
using Azure.AI.Vision.ImageAnalysis;

namespace ImageWebApp.Controllers
{
    public class HomeController : Controller
    {
        private readonly IWebHostEnvironment _env; // This field will store the web hosting environment
        private readonly IConfiguration _configuration;
        private readonly string _visionEndpoint;
        private readonly string _visionKey;

        public HomeController(IWebHostEnvironment env, IConfiguration configuration)
        {
            _env = env; // Initialize the field with the constructor parameter
            _configuration = configuration;
            _visionEndpoint = _configuration.GetValue<string>("VisionEndpoint") ?? "ENDPOINT NOT SET";
            _visionKey = _configuration.GetValue<string>("VisionKey") ?? "KEY NOT SET";
        }

        public IActionResult Index()
        {
            return View(); // Return the index view
        }

        [HttpPost]
        public async Task<IActionResult> Index(ImageModel model)
        {

            if (ModelState.IsValid) // Check if the model is valid
            {
                var fileName = Path.GetFileName(model.ImageFile.FileName); // Get the file name of the uploaded image
                var filePath = Path.Combine(_env.WebRootPath, "images", fileName); // Get the file path to save the image in the wwwroot/images folder
                var GenderNeutral = model.GenderNeutral;
                var RemoveBackground = model.RemoveBackground;
                using (var fileStream = new FileStream(filePath, FileMode.Create)) // Create a file stream to write the image data
                {
                    await model.ImageFile.CopyToAsync(fileStream); // Copy the image data to the file stream
                }
                ViewBag.ImagePath = "/images/" + fileName; // Set the ViewBag property to store the image path for displaying

                // Authenticate
                var serviceOptions = new VisionServiceOptions(
                    new Uri(_visionEndpoint),
                    new AzureKeyCredential(_visionKey));

                // Analyze the image from a file
                using var imageStream = new FileStream(filePath, FileMode.Open);
                
                // Analysis options
                var analysisOptions = new ImageAnalysisOptions()
                {
                    // Specify features to be retrieved
                    Features =
                        ImageAnalysisFeature.Caption
                        | ImageAnalysisFeature.DenseCaptions
                        | ImageAnalysisFeature.Tags
                        | ImageAnalysisFeature.Text
                    ,
                    GenderNeutralCaption = GenderNeutral
                };

                // Analyze the image
                using var imageSource = VisionSource.FromFile(filePath);
                using var analyzer = new ImageAnalyzer(serviceOptions, imageSource, analysisOptions);
                var result = analyzer.Analyze();

                if (result.Reason == ImageAnalysisResultReason.Analyzed)
                {
                    // Get image caption
                    if (result.Caption != null)
                    {
                        ViewBag.Caption = $"{result.Caption.Content} (confidence: {result.Caption.Confidence:0.0000})";
                    }

                    // Get image dense captions
                    if (result.DenseCaptions != null)
                    {

                        var denseCaptions = new List<string>();

                        foreach (var caption in result.DenseCaptions)
                        {
                            denseCaptions.Add($"{caption.Content} (confidence: {caption.Confidence:0.0000})");
                        }
                        ViewBag.DenseCaptions = denseCaptions;

                    }

                    // Get image tags
                    if (result.Tags != null)
                    {
                        var tags = new List<string>();
                        foreach (var tag in result.Tags)
                        {
                            tags.Add($"{tag.Name} (confidence: {tag.Confidence:0.0000})");
                        }
                        ViewBag.Tags = tags;
                    }

                    // Get image text
                    if (result.Text != null)
                    {
                        var lines = new List<string>();
                        foreach (var line in result.Text.Lines)
                        {
                            
                            lines.Add($"{line.Content}");
                        }
                        ViewBag.Lines = lines;
                    }
                }
                if(RemoveBackground)
                {
                    BackgroundRemoval(filePath, serviceOptions);
                }

            }
            return View(model); // Return the index view with the model
     
        }
        public void BackgroundRemoval(string imageFile, VisionServiceOptions serviceOptions)
        {
            using var imageSource = VisionSource.FromFile(imageFile);
            var analysisOptions = new ImageAnalysisOptions()
            {
                SegmentationMode = ImageSegmentationMode.BackgroundRemoval
            };
            using var analyzer = new ImageAnalyzer(serviceOptions, imageSource, analysisOptions);
            var result = analyzer.Analyze();

            // Remove the background
            if(result.Reason == ImageAnalysisResultReason.Analyzed)
            {
                using var segmentationResult = result.SegmentationResult;

                var imageBuffer = segmentationResult.ImageBuffer;
                string outputImageFile = $"{Path.GetFileNameWithoutExtension(imageFile)}_background_removed.png";
                using var fileStream = new FileStream(Path.Combine(_env.WebRootPath, "images", outputImageFile), FileMode.Create);
                fileStream.Write(imageBuffer.Span);
                ViewBag.NewImagePath = Url.Content($"/images/{outputImageFile}");
            }
        }

    }
}
