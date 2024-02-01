using System;
using System.Drawing;
using Microsoft.Extensions.Configuration;
using Azure;
using System.IO;
using Azure.AI.Vision.Common;
using Azure.AI.Vision.ImageAnalysis;

namespace detect_people
{
    class Program
    {

        static void Main(string[] args)
        {
            try
            {
                // Get config settings from AppSettings
                IConfigurationBuilder builder = new ConfigurationBuilder().AddJsonFile("appsettings.json");
                IConfigurationRoot configuration = builder.Build();
                string aiSvcEndpoint = configuration["AIServicesEndpoint"];
                string aiSvcKey = configuration["AIServiceKey"];

                // Get image
                string imageFile = "images/people.jpg";
                if (args.Length > 0)
                {
                    imageFile = args[0];
                }

                // Authenticate Azure AI Vision client
                var cvClient = new VisionServiceOptions(
                    aiSvcEndpoint,
                    new AzureKeyCredential(aiSvcKey));

                
                // Analyze image
                AnalyzeImage(imageFile, cvClient);

            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }
        }

        static void AnalyzeImage(string imageFile, VisionServiceOptions serviceOptions)
        {
            Console.WriteLine($"\nAnalyzing {imageFile} \n");

            var analysisOptions = new ImageAnalysisOptions()
            {
                // Specify features to be retrieved (PEOPLE)
                Features =
                    ImageAnalysisFeature.People
            };

            // Get image analysis
            using var imageSource = VisionSource.FromFile(imageFile);

            using var analyzer = new ImageAnalyzer(serviceOptions, imageSource, analysisOptions);

            var result = analyzer.Analyze();

            if (result.Reason == ImageAnalysisResultReason.Analyzed)
            {
                // Get people in the image
                if (result.People != null)
                {
                    Console.WriteLine($" People:");
                
                    // Prepare image for drawing
                    System.Drawing.Image image = System.Drawing.Image.FromFile(imageFile);
                    Graphics graphics = Graphics.FromImage(image);
                    Pen pen = new Pen(Color.Cyan, 3);
                    Font font = new Font("Arial", 16);
                    SolidBrush brush = new SolidBrush(Color.WhiteSmoke);
                
                    foreach (var person in result.People)
                    {
                        // Draw object bounding box if confidence > 50%
                        if (person.Confidence > 0.5)
                        {
                            // Draw object bounding box
                            var r = person.BoundingBox;
                            Rectangle rect = new Rectangle(r.X, r.Y, r.Width, r.Height);
                            graphics.DrawRectangle(pen, rect);
                
                            // Return the confidence of the person detected
                            Console.WriteLine($"   Bounding box {person.BoundingBox}, Confidence {person.Confidence:0.0000}");
                        }
                    }
                
                    // Save annotated image
                    String output_file = "detected_people.jpg";
                    image.Save(output_file);
                    Console.WriteLine("  Results saved in " + output_file + "\n");
                }
            }
            else
            {
                var errorDetails = ImageAnalysisErrorDetails.FromResult(result);
                Console.WriteLine(" Analysis failed.");
                Console.WriteLine($"   Error reason : {errorDetails.Reason}");
                Console.WriteLine($"   Error code : {errorDetails.ErrorCode}");
                Console.WriteLine($"   Error message: {errorDetails.Message}\n");
            }


        }


    }
}
