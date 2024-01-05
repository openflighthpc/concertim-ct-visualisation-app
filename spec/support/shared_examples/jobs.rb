RSpec.shared_examples "auth token header" do
  it "includes a bearer token in request headers" do
    headers = subject.send(:connection).headers
    expect(headers[:Authorization].present?).to eq true
    expect(headers[:Authorization]).to include "Bearer"
  end

  it "includes appropriate, valid details in bearer token" do
    header = subject.send(:connection).headers[:Authorization]
    token = header.split(" ")[1]
    decoded = Warden::JWTAuth::TokenDecoder.new.call(token)
    expect(decoded["exp"]).to eq decoded["iat"] + 60
  end
end
