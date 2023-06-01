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

# Generic specifications for testing that an update route works as expected.
#
# Including this example group requires defining `url_under_test`,
# `object_under_test`, `valid_attributes` and `invalid_attributes`.  E.g.,
#
#   include_examples "" do
#     let(:url_under_test) { Rails.application.routes.url_helpers.api_v1_user_path(user) }
#     let(:object_under_test) { user }
#     let(:valid_attributes) {
#       {
#         user: { project_id: "new project id" }
#       }
#     }
#     let(:invalid_attributes) {
#       {
#         user: { }
#       }
#     }
#   end
#
# There is an assumption that the URL is an API endpoint consuming JSON and
# producing JSON.  Assertions are added to that effect.
#
# There is an assumption that attributes specified in `valid_attributes` will
# updated exactly as given and that testing these is sufficient.
RSpec.shared_examples "update generic JSON API endpoint examples" do
  let(:param_key) { object_under_test.to_model.model_name.param_key }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:parsed_object_under_test) { parsed_body }

  context "with valid parameters" do
    def send_request
      patch url_under_test,
        params: valid_attributes,
        headers: headers,
        as: :json
    end

    it "renders a successful response" do
      send_request
      expect(response).to have_http_status :ok
    end

    it "updates the object under test" do
      expect {
        send_request
        object_under_test.reload
      }.to change(object_under_test, :updated_at)
    end

    it "updates the expected attributes" do
      expected_changes = nil
      valid_attributes.stringify_keys[param_key].each do |key, value|
        if expected_changes.nil?
          expected_changes = change(object_under_test, key).to(value)
        else
          expected_changes = expected_changes.and change(object_under_test, key).to(value)
        end
      end

      expect {
        send_request
        object_under_test.reload
      }.to expected_changes
    end

    it "includes the object under test in the response" do
      send_request
      expect(parsed_object_under_test["id"]).to eq object_under_test.id
    end
  end

  context "with invalid parameters" do
    def send_request
      patch url_under_test,
        params: invalid_attributes,
        headers: headers,
        as: :json
    end

    it "does not update the object under test" do
      expect {
        send_request
        object_under_test.reload
      }.not_to change(object_under_test, :updated_at)
    end

    it "renders an unprocessable entity response" do
      send_request
      expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:bad_request)
    end
  end
end
