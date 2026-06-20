-- spec/http_spec.lua
local http = require("http")

local function make_mock_internet(responses)
  -- responses: queue of { code = number, body = string }
  local call_log = {}
  local mock = {}
  function mock.request(url, body, headers)
    table.insert(call_log, { url = url, body = body, headers = headers })
    local response = table.remove(responses, 1)
    local chunks_sent = false
    local handle = {}
    function handle.read(n)
      if chunks_sent then
        return nil
      end
      chunks_sent = true
      return response.body
    end
    function handle.response()
      return response.code, "OK", {}
    end
    return handle
  end
  return mock, call_log
end

describe("http client", function()
  it("sends a GET with the auth header and decodes a JSON response", function()
    local mock, log = make_mock_internet({ { code = 200, body = '{"ok":true}' } })
    local client = http.new(mock, "http://example.test", "secret-token")

    local ok, result = client:get_json("/api/client/orders/pending")

    assert.is_true(ok)
    assert.is_true(result.ok)
    assert.are.equal("http://example.test/api/client/orders/pending", log[1].url)
    assert.are.equal("Bearer secret-token", log[1].headers["Authorization"])
  end)

  it("sends a POST with a JSON-encoded body", function()
    local mock, log = make_mock_internet({ { code = 200, body = '{"ok":true}' } })
    local client = http.new(mock, "http://example.test", "secret-token")

    local ok, result = client:post_json("/api/client/flux", { energy_in = 1 })

    assert.is_true(ok)
    assert.are.equal('{"energy_in":1}', log[1].body)
    assert.are.equal("application/json", log[1].headers["Content-Type"])
  end)

  it("returns ok=false on a non-2xx response", function()
    local mock, _ = make_mock_internet({ { code = 401, body = "unauthorized" } })
    local client = http.new(mock, "http://example.test", "bad-token")

    local ok, result = client:get_json("/api/client/orders/pending")

    assert.is_false(ok)
    assert.matches("401", result)
  end)

  it("returns ok=false when the response body is not valid JSON", function()
    local mock, _ = make_mock_internet({ { code = 200, body = "not json" } })
    local client = http.new(mock, "http://example.test", "secret-token")

    local ok, result = client:get_json("/api/client/orders/pending")

    assert.is_false(ok)
  end)
end)
