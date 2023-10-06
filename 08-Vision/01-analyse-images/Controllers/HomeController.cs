using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using ImageWebApp.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using System.Text;
using System.Runtime.CompilerServices;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision.Models;

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

            if(model.InputText != null)
            {
                string visionEndpoint = $"{_visionEndpoint}vision/v3.1/analyze?visualFeatures=Description";
                RestResponse URLResult = await RestRequest(visionEndpoint, model.InputText);
                // Parse the JSON response and get the language
                JObject urlJson = JObject.Parse(URLResult.Result);
                ViewBag.URLResult = urlJson;
                ViewBag.ImgURL = model.InputText;
                Console.WriteLine(urlJson);
            }

            if (ModelState.IsValid) // Check if the model is valid
            {                
                var fileName = Path.GetFileName(model.ImageFile.FileName); // Get the file name of the uploaded image
                var filePath = Path.Combine(_env.WebRootPath, "images", fileName); // Get the file path to save the image in the wwwroot/images folder
                using (var fileStream = new FileStream(filePath, FileMode.Create)) // Create a file stream to write the image data
                {
                    await model.ImageFile.CopyToAsync(fileStream); // Copy the image data to the file stream
                }
                ViewBag.ImagePath = "/images/" + fileName; // Set the ViewBag property to store the image path for displaying

                ComputerVisionClient visionClient = new (new ApiKeyServiceClientCredentials(_visionKey))
                {
                    Endpoint = _visionEndpoint
                };

                // Specify the features to analyze
                List<VisualFeatureTypes?> features = new()
                {
                    VisualFeatureTypes.Description
                };

                using(var imageStream = new FileStream(filePath, FileMode.Open))
                {
                    // Analyze the image
                    ImageAnalysis analysis = await visionClient.AnalyzeImageInStreamAsync(imageStream, features);

                    // Get image captions
                    foreach(ImageCaption caption in analysis.Description.Captions)
                    {
                        ViewBag.Caption = caption.Text;
                    }
                }
                GetThumbnail(filePath, visionClient).Wait();

            }
            return View(model); // Return the index view with the model
     
        }

        public async Task GetThumbnail(string imageFile, ComputerVisionClient client)
        {
            // Generate a thumbnail
            using (var imageData = System.IO.File.OpenRead(imageFile))
            {
                // Get thumbnail data
                var thumbnailStream = await client.GenerateThumbnailInStreamAsync(100, 100,imageData, true);

                // Save thumbnail image
                string thumbnailFileName = "thumbnail.png";
                var filePath = Path.Combine(_env.WebRootPath, "images", thumbnailFileName);
                using (Stream thumbnailFile = System.IO.File.Create(filePath))
                {
                    thumbnailStream.CopyTo(thumbnailFile);
                }

                Console.WriteLine($"Thumbnail saved in {filePath}");
            }

        }
        public async Task<RestResponse> RestRequest(string endpoint, string path)
        {
            JObject jsonBody = new()
            {
                ["url"] = path
            };

            var client = new HttpClient();
            var request = new HttpRequestMessage
            {
                Method = HttpMethod.Post,
                RequestUri = new Uri(endpoint),
                Content = new StringContent(jsonBody.ToString(), Encoding.UTF8, "application/json"),
                Headers = {
                    { "Ocp-Apim-Subscription-Key", _visionKey },
                    { "ContentType", "application/json"},
                },
            };
            // Send the request and get the response
            HttpResponseMessage response = await client.SendAsync(request).ConfigureAwait(false);
            string result = await response.Content.ReadAsStringAsync();

            RestResponse restResponse = new()
            {
                Result = result,
                Method = request.Method.ToString(),
                Uri = request.RequestUri.ToString(),
                Body = request.Content.ReadAsStringAsync().Result.ToString()
            };

            return restResponse;
        }

    }
    public class RestResponse
    {
        public string Result { get; set; }
        public string? Method { get; set; }
        public string? Uri { get; set; }
        public string? Body { get; set; }
    }
}
