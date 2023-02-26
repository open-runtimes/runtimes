using System;
using Newtonsoft.Json;

static readonly HttpClient http = new();

public async Task<RuntimeResponse> Main(RuntimeRequest req, RuntimeResponse res)
{
    string id = "1";
    if (!string.IsNullOrEmpty(req.Payload))
    {
        var payload = JsonConvert.DeserializeObject<Dictionary<string, object>>(req.Payload, settings: null);
        id = payload?.TryGetValue("id", out var value) == true
            ? value.ToString()!
            : "1";
    }

    var header = req.Headers.ContainsKey("x-test-header")
        ? req.Headers["x-test-header"]
        : "";

    var varData = req.Variables.ContainsKey("test-variable")
        ? req.Variables["test-variable"]
        : "";

    var response = await http.GetStringAsync($"https://jsonplaceholder.typicode.com/todos/{id}");
    var todo = JsonConvert.DeserializeObject<Dictionary<string, object>>(response, settings: null);

    Console.WriteLine("String1");
    Console.WriteLine(42);
    Console.WriteLine(4.2);
    Console.WriteLine(true);

    Console.WriteLine("String2");
    Console.WriteLine("String3");
    Console.WriteLine("String4");
    Console.WriteLine("String5");

    return res.Json(new()
    {
        { "isTest", true },
        { "message", "Hello Open Runtimes 👋" },
        { "header", header },
        { "variable", varData },
        { "todo", todo }
    });
}