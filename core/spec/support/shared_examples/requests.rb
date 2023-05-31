RSpec.shared_examples "successful JSON response" do
  it "renders a successful response" do
    get url_under_test, headers: headers, as: :json
    expect(response).to be_successful
  end

  it "returns a JSON document" do
    get url_under_test, headers: headers, as: :json
    expect{ JSON.parse(response.body) }.not_to raise_error
  end
end

RSpec.shared_examples "unauthorised JSON response" do
  let(:request_method) { :get }

  it "returns an unauthorised response" do
    send(request_method, url_under_test, headers: headers, as: :json)
    expect(response).to have_http_status :unauthorized
  end

  it "returns an unauthorised response error message as JSON" do
    send(request_method, url_under_test, headers: headers, as: :json)
    expect(response.body).to eq ({error: "You need to sign in or sign up before continuing."}.to_json)
  end
end

RSpec.shared_examples "forbidden JSON response" do
  let(:request_method) { :get }

  it "returns a forbidden response" do
    send(request_method, url_under_test, headers: headers, as: :json)
    expect(response).to have_http_status :forbidden
  end

  it "returns an unauthorised response error message as JSON" do
    send(request_method, url_under_test, headers: headers, as: :json)
    parsed_body = JSON.parse(response.body)
    expect(parsed_body["errors"][0]["title"]).to eq "Not Authorized"
  end
end
