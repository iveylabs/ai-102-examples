using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;

// Import namespaces
using Microsoft.Azure.CognitiveServices.Vision.Face;
using Microsoft.Azure.CognitiveServices.Vision.Face.Models;


namespace analyze_faces
{
    class Program
    {

        private static FaceClient faceClient;
        static async Task Main(string[] args)
        {
            try
            {
                // Get config settings from AppSettings
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
                IConfigurationRoot configuration = builder.Build();
                string cogSvcEndpoint = configuration["CognitiveServicesEndpoint"];
                string cogSvcKey = configuration["CognitiveServiceKey"];

                // Authenticate Face client
                ApiKeyServiceClientCredentials credentials = new ApiKeyServiceClientCredentials(cogSvcKey);
                faceClient = new FaceClient(credentials)
                {
                    Endpoint = cogSvcEndpoint
                };

                // Menu for face functions
                Console.WriteLine("1-2: Detect faces\nAny other key to quit");
                Console.WriteLine("Enter a number:");
                string command = Console.ReadLine();
                switch (command)
                {
                    case "1":
                        await DetectFaces("images/people.jpg", 1);
                        break;
                    case "2":
                        await DetectFaces("images/people2.jpg", 2);
                        break;
                    default:
                        break;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }

        static async Task DetectFaces(string imageFile, int num)
        {
            Console.WriteLine($"Detecting faces in {imageFile}");

            // Specify facial features to be retrieved
            List<FaceAttributeType?> features = new List<FaceAttributeType?>
            {
                FaceAttributeType.Occlusion,
                FaceAttributeType.Blur,
                FaceAttributeType.Glasses
            };

            // Get faces
            using var imageData = File.OpenRead(imageFile);
            var detected_faces = await faceClient.Face.DetectWithStreamAsync(imageData, returnFaceAttributes: features, returnFaceId: true);

            if (detected_faces.Count > 0)
            {
                Console.WriteLine($"{detected_faces.Count} faces detected.");

                // Prepare image for drawing
                Image image = Image.FromFile(imageFile);
                Graphics graphics = Graphics.FromImage(image);
                Pen pen = new Pen(Color.LightGreen, 3);
                Font font = new Font("Arial", 4);
                SolidBrush brush = new SolidBrush(Color.White);
                int faceCount = 0;

                // Draw and annotate each face
                foreach (var face in detected_faces)
                {
                    faceCount++;
                    Console.WriteLine($"\nFace number {faceCount}");

                    // Get face properties
                    Console.WriteLine($" - Mouth Occluded: {face.FaceAttributes.Occlusion.MouthOccluded}");
                    Console.WriteLine($" - Eye Occluded: {face.FaceAttributes.Occlusion.EyeOccluded}");
                    Console.WriteLine($" - Blur: {face.FaceAttributes.Blur.BlurLevel}");
                    Console.WriteLine($" - Glasses: {face.FaceAttributes.Glasses}");
                    Console.WriteLine($" - FaceId: {face.FaceId}");

                    // Draw and annotate face
                    var r = face.FaceRectangle;
                    Rectangle rect = new Rectangle(r.Left, r.Top, r.Width, r.Height);
                    graphics.DrawRectangle(pen, rect);
                    string faceId = $"FaceId: {face.FaceId}";
                    string faceAttributes = $"Glasses: {face.FaceAttributes.Glasses}";
                    graphics.DrawString(faceId, font, brush, r.Left, r.Top - 20);
                    graphics.DrawString(faceAttributes, font, brush, r.Left, r.Top + r.Height + 5);
                }

                // Save annotated image
                String output_file = $"detected_faces{num}.jpg";
                image.Save(output_file);
                Console.WriteLine(" Results saved in " + output_file);
            }

        }
    }
}
