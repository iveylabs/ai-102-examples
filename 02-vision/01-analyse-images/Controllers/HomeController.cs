using ImageWebApp.Models;
using Microsoft.AspNetCore.Mvc;
using Azure;
using Azure.AI.Vision.ImageAnalysis;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text;
using Microsoft.AspNetCore.Http.Features;

namespace _01_analyse_images.Controllers;

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
            ImageAnalysisClient client = new (
                new Uri(_visionEndpoint),
                new AzureKeyCredential(_visionKey));
            
            // Analysis options
            ImageAnalysisOptions analysisOptions = new()
            {
                GenderNeutralCaption = GenderNeutral
            };

            // Open the file in a stream
            using FileStream stream = new(filePath, FileMode.Open);

            // Analyse the image
            ImageAnalysisResult result = client.Analyze(
                BinaryData.FromStream(stream),
                VisualFeatures.Caption |
                VisualFeatures.DenseCaptions |
                VisualFeatures.Tags |
                VisualFeatures.Read,
                analysisOptions
            );

            // Get image caption
            if (result.Caption != null)
            {
                ViewBag.Caption = $"{result.Caption.Text} (confidence: {result.Caption.Confidence:0.0000})";
            }

            // Get image dense captions
            if (result.DenseCaptions != null)
            {

                var denseCaptions = new List<string>();

                foreach (var caption in result.DenseCaptions.Values)
                {
                    denseCaptions.Add($"{caption.Text} (confidence: {caption.Confidence:0.0000})");
                }
                ViewBag.DenseCaptions = denseCaptions;

            }

            // Get image tags
            if (result.Tags != null)
            {
                var tags = new List<string>();
                foreach (var tag in result.Tags.Values)
                {
                    tags.Add($"{tag.Name} (confidence: {tag.Confidence:0.0000})");
                }
                ViewBag.Tags = tags;
            }

            // Get image text
            if (result.Read != null)
            {
                var lines = new List<string>();
                foreach (var block in result.Read.Blocks)
                {
                    foreach (var line in block.Lines)
                    
                    lines.Add($"{line.Text}");
                }
                ViewBag.Lines = lines;
            }

            if(RemoveBackground)
            {
                string outputImageFile = $"{Path.GetFileNameWithoutExtension(filePath)}_background_removed.png";
                string newImagePath = Url.Content($"/images/{outputImageFile}");
                await BackgroundRemoval(filePath, newImagePath, outputImageFile);
            }

        }
        return View(model); // Return the index view with the model
 
    }
    public async Task BackgroundRemoval(string filePath, string newImagePath, string outputImageFile)
    {
        string apiVersion = "2023-02-01-preview";
        string mode = "backgroundRemoval";
        string url = $"{_visionEndpoint}computervision/imageanalysis:segment?overload=stream&api-version={apiVersion}&mode={mode}";

        using var client = new HttpClient();
        client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", _visionKey);

        using var stream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
        var byteData = new byte[stream.Length];
        await stream.ReadAsync(byteData.AsMemory(0, (int)stream.Length));

        using var content = new ByteArrayContent(byteData);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
        var response = await client.PostAsync(url, content);

        if(response.IsSuccessStatusCode)
        {
            using var fileStream = new FileStream(Path.Combine(_env.WebRootPath, "images", outputImageFile), FileMode.Create);
            fileStream.Write(await response.Content.ReadAsByteArrayAsync());

            ViewBag.NewImagePath = newImagePath;
        }
        else
        {
            Console.WriteLine("It didn't work");
        }
    }

}
