var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddHttpClient();
builder.Services.AddSingleton(builder.Configuration);
builder.Services.AddSingleton(builder.Configuration.GetValue<string>("LanguageEndpoint")!);
builder.Services.AddSingleton(builder.Configuration.GetValue<string>("LanguageKey")!);
builder.Services.AddSingleton(builder.Configuration.GetValue<string>("WeatherApiKey")!);
builder.Services.AddSingleton(builder.Configuration.GetValue<string>("ProjectName")!);
builder.Services.AddSingleton(builder.Configuration.GetValue<string>("DeploymentName")!);


var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.Run();
