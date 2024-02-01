using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Newtonsoft.Json.Linq;
using System.Text;

namespace GettingStarted.Pages;

public class IndexModel : PageModel
{
    private readonly IConfiguration _configuration;
    private readonly string _serviceKey;
    private readonly string _serviceEndpoint;

    public IndexModel(IConfiguration configuration)
    {
        _configuration = configuration;
        _serviceKey = _configuration.GetValue<string>("ServiceKey") ?? "KEY NOT SET";
        _serviceEndpoint = _configuration.GetValue<string>("ServiceEndpoint") ?? "ENDPOINT NOT SET";
    }

    public async Task<IActionResult> OnPostProcessInputAsync(string InputText)
    {
        // Set up endpoint
        string languageEndpoint = $"{_serviceEndpoint}language/:analyze-text?api-version=2023-04-01";

        // Process the input text
        string originalText =  InputText;

        // Set the original text to output
        ViewData["OriginalText"] = originalText;

        // Get language
        RestResponse languageResponse = await RestRequest(languageEndpoint, originalText);

        // Parse the JSON response and get the language
        JObject languageJson = JObject.Parse(languageResponse.Result);
        string? language = languageJson["documents"]?[0]?["detectedLanguage"]?["name"]?.ToString();
        string? languageConfidence = languageJson["documents"]?[0]?["detectedLanguage"]?["confidenceScore"]?.ToString();

        // Set the language information to output
        ViewData["Language"] = language;
        ViewData["LanguageConfidence"] = languageConfidence;
        ViewData["LanguageMethod"] = languageResponse.Method;
        ViewData["LanguageUri"] = languageResponse.Uri;
        ViewData["LanguageBody"] = JToken.Parse(languageResponse.Body);
        ViewData["LanguageResponse"] = languageJson;
        if(languageResponse.Headers.Contains("Ocp-Apim-Subscription-Key"))
        {
            ViewData["LanguageHeaders"] = "Ocp-Apim-Subscription-Key";
        }
        else
        {
        ViewData["LanguageHeaders"] = "None";
        }

        return Page();
    }

    public void OnGet()
    {
        
    }

    public async Task<RestResponse> RestRequest(string endpoint, string originalText)
    {
        JObject jsonBody = new()
        {
            ["kind"] = "LanguageDetection",
            ["parameters"] = new JObject
            {
                ["modelVersion"] = "latest"
            },
            ["analysisInput"] = new JObject
            {
                ["documents"] = new JArray
                {
                    new JObject
                    {
                        ["id"] = "1",
                        ["text"] = originalText
                    }
                }
            }
        };
        var client = new HttpClient();
        var request = new HttpRequestMessage
        {
            Method = HttpMethod.Post,
            RequestUri = new Uri(endpoint),
            Content = new StringContent(jsonBody.ToString(), Encoding.UTF8, "application/json"),
        };

        // Only use the key if the _cognitiveServicesEndpoint is does not contain localhost
        if (!_serviceEndpoint.Contains("localhost"))
        {
            request.Headers.Add("Ocp-Apim-Subscription-Key", _serviceKey);
        }

        // Send the request and get the response
        HttpResponseMessage response = await client.SendAsync(request).ConfigureAwait(false);
        string result = await response.Content.ReadAsStringAsync();

        RestResponse restResponse = new()
        {
            Result = result,
            Method = request.Method.ToString(),
            Uri = request.RequestUri.ToString(),
            Body = request.Content.ReadAsStringAsync().Result.ToString(),
            Headers = request.Headers.First().Key
        };

        return restResponse;
    }
    public class RestResponse
    {
        public string Result { get; set; }
        public string? Method { get; set; }
        public string? Uri { get; set; }
        public string? Body { get; set; }
        public string? Headers { get; set; }
    }
}
