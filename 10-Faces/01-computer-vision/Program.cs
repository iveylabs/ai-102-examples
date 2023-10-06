using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

// Import namespaces
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision;
using Microsoft.Azure.CognitiveServices.Vision.ComputerVision.Models;

namespace detect_faces
{
    class Program
    {

        private static ComputerVisionClient cvClient;
        static async Task Main(string[] args)
        {
            try
            {
                // Get config settings from AppSettings
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
                IConfigurationRoot configuration = builder.Build();
                string cogSvcEndpoint = configuration["CognitiveServicesEndpoint"];
                string cogSvcKey = configuration["CognitiveServiceKey"];

                // Authenticate Computer Vision client
                ApiKeyServiceClientCredentials credentials = new ApiKeyServiceClientCredentials(cogSvcKey);
                cvClient = new ComputerVisionClient(credentials)
                {
                    Endpoint = cogSvcEndpoint
                };


                // Detect faces in an image
                string imageFile = "images/people.jpg";
                await AnalyzeFaces(imageFile);
               
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }

        static async Task AnalyzeFaces(string imageFile)
        {
            Console.WriteLine($"Analyzing {imageFile}");

            // Specify features to be retrieved (faces)
            List<VisualFeatureTypes?> features = new List<VisualFeatureTypes?>()
            {
                VisualFeatureTypes.Faces
            };


            // Get image analysis
            using var imageData = File.OpenRead(imageFile);
            var analysis = await cvClient.AnalyzeImageInStreamAsync(imageData, features);

            // Get faces
            if (analysis.Faces.Count > 0)
            {
                Console.WriteLine($"{analysis.Faces.Count} faces detected.");

                // Prepare image for drawing
                Image image = Image.FromFile(imageFile);
                Graphics graphics = Graphics.FromImage(image);
                Pen pen = new Pen(Color.LightGreen, 3);
                Font font = new Font("Arial", 3);
                SolidBrush brush = new SolidBrush(Color.LightGreen);

                // Draw and annotate each face
                foreach (var face in analysis.Faces)
                {
                    var r = face.FaceRectangle;
                    Rectangle rect = new Rectangle(r.Left, r.Top, r.Width, r.Height);
                    graphics.DrawRectangle(pen, rect);
                    string annotation = $"Person at approximately {r.Left}, {r.Top}";
                    graphics.DrawString(annotation, font, brush, r.Left, r.Top);
                }

                // Save annotated image
                String output_file = "detected_faces.jpg";
                image.Save(output_file);
                Console.WriteLine(" Results saved in " + output_file);
            }

        }


    }
}
