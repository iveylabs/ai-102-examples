using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Text.Json;
using Azure;
using Azure.Core;
using Azure.Core.Serialization;
using Azure.AI.Language.Conversations;
using Newtonsoft.Json.Linq;
using System.Text.Json.Nodes;

namespace CLU.Pages;

public class IndexModel : PageModel
{
    private readonly IConfiguration _configuration;
    private readonly string _languageKey;
    private readonly string _languageEndpoint;
    private readonly string _weatherApiKey;


    public IndexModel(IConfiguration configuration)
    {
        _configuration = configuration;
        _languageEndpoint = _configuration.GetValue<string>("LanguageEndpoint") ?? "KEY NOT SET";
        _languageKey = _configuration.GetValue<string>("LanguageKey") ?? "ENDPOINT NOT SET";
        _weatherApiKey = _configuration.GetValue<string>("WeatherApiKey") ?? "WEATHER API KEY NOT SET";
    }

    public async Task<IActionResult> OnPostProcessInputAsync(string InputText, string submit)
    {
        string inputText = InputText;

        if (submit == "SDK")
        {
            // Set up the language client
            Uri endpoint = new Uri(_languageEndpoint);
            AzureKeyCredential credential = new AzureKeyCredential(_languageKey);
            ConversationAnalysisClient client = new ConversationAnalysisClient(endpoint, credential);

            var projectName = "AI-102Demo";
            var deploymentName = "production";

            var data = new
            {
                analysisInput = new
                {
                    conversationItem = new
                    {
                        text = inputText,
                        id = "1",
                        participantId = "1"
                    }
                },
                parameters = new
                {
                    projectName,
                    deploymentName,

                    // Use Utf16CodeUnit for strings in .NET.
                    stringIndexType = "Utf16CodeUnit",
                },
                kind = "Conversation",
            };

            // Send the request
            Response response = await client.AnalyzeConversationAsync(RequestContent.Create(data));
            dynamic conversationalTaskResult = response.Content.ToDynamicFromJson(JsonPropertyNames.CamelCase);
            dynamic conversationPrediction = conversationalTaskResult.Result.Prediction;
            var options = new JsonSerializerOptions { WriteIndented = true };
            var topIntent = "";
            if (conversationPrediction.Intents[0].ConfidenceScore > 0.5)
            {
                topIntent = conversationPrediction.TopIntent;
            }

            Console.WriteLine($"Response: \n{JsonSerializer.Serialize(conversationalTaskResult, options)}");

            ViewData["TopIntent"] = topIntent;

            switch(topIntent)
            {
                case "GetDate":
                    var day = DateTime.Now.DayOfWeek.ToString();
                    // Check for a weekday entity
                    foreach(dynamic entity in conversationPrediction.Entities)
                    {
                        if(entity.Category == "Weekday")
                        {
                            day = entity.Text;
                            ViewData["Entity"] = day;
                        }
                    }
                    // Get the date
                    ViewData["Date"] = GetDate(day);
                    break;
                case "GetWeather":
                    string location = "Cheltenham";
                    // Check for a location entity
                    foreach(dynamic entity in conversationPrediction.Entities)
                    {
                        if(entity.Category == "Location" )
                        {
                            location = entity.Text;
                        }
                    }
                    // Get the weather
                    ViewData["Weather"] = GetWeather(location).Result.Weather.ToString();
                    ViewData["Entity"] = location;
                    break;
                default:
                    // Some other intent (for example, "None") was predicted
                    ViewData["None"] = "None";
                    break;
            }
        }
        return Page();
    }

    static string GetDate(string day)
    {
        string date_string = "I can only determine dates for today or named days of the week.";

        // To keep things simple, assume the named day is in the current week (Sunday to Saturday)
        if (Enum.TryParse(day, true, out DayOfWeek weekDay))
        {
            int weekDayNum = (int)weekDay;
            int todayNum = (int)DateTime.Today.DayOfWeek;
            int offset = weekDayNum - todayNum;
            date_string = DateTime.Today.AddDays(offset).ToShortDateString();
        }
        return date_string;
    }

    async Task<RestResponse> GetWeather(string location)
    {
        string url = $"https://api.openweathermap.org/data/2.5/weather?q={location}&appid={_weatherApiKey}&units=metric";
        using var client = new HttpClient();
        var response = await client.GetAsync(url);

        var content = await response.Content.ReadAsStringAsync();
        JObject json = JObject.Parse(content);
        // string weather = $"The weather in {location} is {json["weather"]?[0]?["description"]} with a temperature of {json["main"]?["temp"]} degrees Celsius.";
        RestResponse restResponse = new()
        {
            Weather = $"{json["weather"]?[0]?["description"]} with a temperature of {json["main"]?["temp"]} degrees Celsius."
        };
        return restResponse;

    }
}

public class RestResponse
{
    public string Weather { get; set; }
}