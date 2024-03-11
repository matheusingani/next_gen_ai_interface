require "json"

class Example < ApplicationRecord
  belongs_to :template
  has_many :example_fields
  after_create :generate_example_field

  accepts_nested_attributes_for :example_fields


  def generate_example_field
    client = OpenAI::Client.new
    chaptgpt_response = client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: "given #{content}, give me the key value pairs of the information keywords in it, in a json with the name example_field"}]
    })
    json_string = chaptgpt_response["choices"][0]["message"]["content"]
    ruby_object = JSON.parse(json_string)
    ruby_object["example_field"].each do |key, value|
      ExampleField.create!(key: key, value: value, example: self)
    end
    generate_content_example(ruby_object)
  end

  def generate_content_example(ruby_object)
    client = OpenAI::Client.new
    chaptgpt_response = client.chat(parameters: {
      model: "gpt-3.5-turbo",
      messages: [{ role: "user", content: "#{content}, replace in this text each of #{ruby_object["example_field"].keys} in the corresponding place like this <key>"}]
    })
    output_from_api = chaptgpt_response["choices"][0]["message"]["content"]
    update(content: output_from_api)
  end
end
