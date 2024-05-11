using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Text.Json;
using System.IO;
using Azure;
using Azure.Core;
using Azure.Core.Serialization;
using Azure.AI.Language.Conversations;
using Newtonsoft.Json.Linq;
using System.Text.Json.Nodes;
using System.Text;

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

        // SDK
        if (submit == "SDK")
        {
            // Set up the language client
            Uri endpoint = new (_languageEndpoint);
            AzureKeyCredential credential = new (_languageKey);
            ConversationAnalysisClient client = new (endpoint, credential);

            var projectName = "AI-102CLUDemo";
            var deploymentName = "AI102CLUDemoDeployment";

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
            var topIntent = "";

            if (conversationPrediction.Intents[0].ConfidenceScore > 0.5)
            {
                topIntent = conversationPrediction.TopIntent;
            }

            Stream contentStream = response.ContentStream;
            StreamReader reader = new (contentStream, Encoding.UTF8);
            string content = reader.ReadToEnd();
            JObject jsonObject = JObject.Parse(content);

            ViewData["Response"] = jsonObject;
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
                            day = entity.extraInformation[0].key;
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
        
        // REST
        else if(submit == "REST")
        {
            string endpoint = $"{_languageEndpoint}language/:analyze-conversations?api-version=2022-10-01-preview";

            // Query the model
            RestResponse restResponse = await RestRequest(endpoint, inputText);

            // Parse the JSON response
            JObject json = JObject.Parse(restResponse.Result);

            string? topIntent = json["result"]?["prediction"]?["topIntent"]?.ToString();

            switch(topIntent)
            {
                case "GetDate":
                    var day = DateTime.Now.DayOfWeek.ToString();
                    // Check for a weekday entity
                    if(json["result"]?["prediction"]?["entities"]?[0]?["category"]?.ToString() == "Weekday")
                    {
                        day = json["result"]?["prediction"]?["entities"]?[0]?["extraInformation"]?[0]?["key"]?.ToString();
                        ViewData["Entity"] = day;
                    }

                    // Get the date
                    ViewData["Date"] = GetDate(day);
                    break;

                case "GetWeather":
                    string? location = "Cheltenham";
                    // Check for a location entity

                    if(json["result"]?["prediction"]?["entities"]?[0]?["category"]?.ToString() == "Location" )
                    {
                        location = json["result"]?["prediction"]?["entities"]?[0]?["text"]?.ToString();
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

            ViewData["TopIntent"] = topIntent;
            ViewData["RESTMethod"] = restResponse.Method;
            ViewData["RESTUri"] = restResponse.Uri;
            ViewData["RESTBody"] = JToken.Parse(restResponse.Body);
            ViewData["Response"] = json;
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
            if(date_string.StartsWith("05/10/"))
            {
                date_string = $"{date_string} (your birthday!)";
            }
            if(date_string.StartsWith("14/02/"))
            {
                date_string = $"{date_string} (Valentine's Day!🌹)";
            }
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
        RestResponse restResponse = new()
        {
            Weather = $"{json["weather"]?[0]?["description"]} with a temperature of {json["main"]?["temp"]} degrees Celsius."
        };
        return restResponse;

    }

    public async Task<RestResponse> RestRequest(string endpoint, string originalText)
    {
        JObject jsonBody = new()
        {
            ["kind"] = "Conversation",
            ["analysisInput"] = new JObject
            {
                ["conversationItem"] = new JObject
                {
                    ["id"] = "1",
                    ["participantId"] = "1",
                    ["text"] = originalText
                }
            },
            ["parameters"] = new JObject
            {
                ["projectName"] = "AI-102CLUDemo",
                ["deploymentName"] = "AI102CLUDemoDeployment",
                ["stringIndexType"] = "Utf16CodeUnit"
            }

        };

        var client = new HttpClient();
        var request = new HttpRequestMessage
        {
            Method = HttpMethod.Post,
            RequestUri = new Uri(endpoint),
            Content = new StringContent(jsonBody.ToString(), Encoding.UTF8, "application/json"),
            Headers = {
                { "Ocp-Apim-Subscription-Key", _languageKey },
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
    public string Weather { get; set; }
    public string Result { get; set; }
    public string? Method { get; set; }
    public string? Uri { get; set; }
    public string? Body { get; set; }
}