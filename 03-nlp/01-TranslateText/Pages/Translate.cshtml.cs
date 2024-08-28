using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Collections.Generic;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc.Rendering;
using Newtonsoft.Json.Linq;
using System.Text;

namespace TranslateText.Pages;

public class TranslateModel : PageModel
{
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;

    public TranslateModel(IConfiguration configuration, HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
    }

    public List<SelectListItem> Languages { get; set; }

    [BindProperty]
    public string FromLanguage { get; set; }

    [BindProperty]
    public string ToLanguage { get; set; }

    [BindProperty]
    public bool MaskProfanity { get; set; }

    // Populate the list of supported languages when the page is loaded
    public async Task OnGetAsync()
    {
        string translatorEndpoint = _configuration.GetValue<string>("TranslatorEndpoint") ?? "TranslatorEndpoint NOT SET";

        // Make a GET request to the Text Translation API to get a list of all supported languages
        string endpoint = $"{translatorEndpoint}/languages?api-version=3.0&scope=translation";

        HttpResponseMessage response = await _httpClient.GetAsync(endpoint);
        response.EnsureSuccessStatusCode();
        string responseBody = await response.Content.ReadAsStringAsync();

        // Parse the JSON response to extract the language codes and names
        var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
        var languageData = JsonSerializer.Deserialize<LanguageData>(responseBody, options);
        Languages = new List<SelectListItem>
        {
            // Set default value (which will be null for From and en for To)
            new SelectListItem { Value = "default", Text = "Default" }
        };

        foreach (var language in languageData.Translation)
        {
            Languages.Add(new SelectListItem { Value = language.Key.ToString(), Text = $"{language.Value["name"]} ({language.Value["nativeName"]})" });
        }
    }

    public async Task<IActionResult> OnPostProcessInputAsync(string InputText, string FromLanguage, string ToLanguage)
    {
        string translatorEndpoint = _configuration.GetValue<string>("TranslatorEndpoint") ?? "TranslatorEndpoint NOT SET";
        string cognitiveServiceKey = _configuration.GetValue<string>("CognitiveServiceKey") ?? "CognitiveServiceKey NOT SET";
        string cognitiveServiceRegion = _configuration.GetValue<string>("CognitiveServiceRegion") ?? "CognitiveServiceRegion NOT SET";
        string originalText = InputText;

        // If FromLanguage is Default, detect the language
        if (FromLanguage == "default")
        {
            try
            {
                object[] body = new object[] { new { Text = originalText } };
                var requestBody = JsonSerializer.Serialize(body);
                using var client = new HttpClient();
                using var request = new HttpRequestMessage();

                // Build the request
                string path = "/detect?api-version=3.0";
                request.Method = HttpMethod.Post;
                request.RequestUri = new Uri(translatorEndpoint + path);
                request.Content = new StringContent(requestBody, Encoding.UTF8, "application/json");
                request.Headers.Add("Ocp-Apim-Subscription-Key", cognitiveServiceKey);
                request.Headers.Add("Ocp-Apim-Subscription-Region", cognitiveServiceRegion);

                // Send the request and get response
                HttpResponseMessage response = await client.SendAsync(request).ConfigureAwait(false);

                // Read the response as a string
                string result = await response.Content.ReadAsStringAsync();

                // Parse the JSON response and get the detected language
                JArray json = JArray.Parse(result);
                FromLanguage = json[0]["language"].ToString();

                // Get the request details to show on the page
                ViewData["DetectMethod"] = request.Method;
                ViewData["DetectUri"] = request.RequestUri;
                ViewData["DetectBody"] = request.Content.ReadAsStringAsync().Result.ToString();
            }
            catch
            {
                FromLanguage = "en";
            }
        }

        // If ToLanguage is Default, set it to en
        if (ToLanguage == "default")
        {
            ToLanguage = "en";
        }

        // Build the translation request
        // If MaskProfanity is true, mask profanity
        string route = $"/translate?api-version=3.0&from={FromLanguage}&to={ToLanguage}";
        if (MaskProfanity)
        {
            route = $"/translate?api-version=3.0&from={FromLanguage}&to={ToLanguage}&profanityAction=Marked";
        }
        object[] translateBody = new object[] { new { Text = originalText } };
        var translateRequestBody = JsonSerializer.Serialize(translateBody);
        using var translateClient = new HttpClient();
        using var translateRequest = new HttpRequestMessage();
        translateRequest.Method = HttpMethod.Post;
        translateRequest.RequestUri = new Uri(translatorEndpoint + route);
        translateRequest.Content = new StringContent(translateRequestBody, Encoding.UTF8, "application/json");
        translateRequest.Headers.Add("Ocp-Apim-Subscription-Key", cognitiveServiceKey);
        translateRequest.Headers.Add("Ocp-Apim-Subscription-Region", cognitiveServiceRegion);

        // Send the request and get response
        HttpResponseMessage translateResponse = await translateClient.SendAsync(translateRequest).ConfigureAwait(false);

        // Read the response as a string
        string translateResult = await translateResponse.Content.ReadAsStringAsync();
        Console.WriteLine("API Response: " + translateResult);

        if (string.IsNullOrEmpty(translateResult))
        {
            ViewData["TranslatedText"] = "Translation response is empty.";
        }
        else
        {
            // Check if the JSON is an array or an object
            if (translateResult.Trim().StartsWith("["))
            {
                // Parse the JSON response and get the translated text
                JArray translateJson = JArray.Parse(translateResult);
                if (translateJson[0]["translations"] != null)
                {
                    string translatedText = translateJson[0]["translations"][0]["text"].ToString();
                    ViewData["TranslatedText"] = translatedText;
                    ViewData["TranslateResponse"] = translateJson;
                }
                else
                {
                    ViewData["TranslatedText"] = "No translations found in the response.";
                }
            }
            else
            {
                // Handle the case where the JSON is an object
                JObject translateJson = JObject.Parse(translateResult);
                if (translateJson["translations"] != null)
                {
                    string translatedText = translateJson["translations"][0]["text"].ToString();
                    ViewData["TranslatedText"] = translatedText;
                    ViewData["TranslateResponse"] = translateJson;
                }
                else
                {
                    ViewData["TranslatedText"] = "No translations found in the response.";
                }
            }
        }

        ViewData["TranslateMethod"] = translateRequest.Method;
        ViewData["TranslateUri"] = translateRequest.RequestUri;
        ViewData["TranslateBody"] = translateRequest.Content.ReadAsStringAsync().Result.ToString();

        ViewData["OriginalText"] = originalText;
        ViewData["FromLanguage"] = FromLanguage;
        ViewData["ToLanguage"] = ToLanguage;

        await OnGetAsync();
        return Page();
    }

    public class LanguageData
    {
        public Dictionary<string, Dictionary<string, string>> Translation { get; set; }
        public Dictionary<string, Dictionary<string, string>> Transliteration { get; set; }
    }
}
