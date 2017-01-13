require 'rails_helper'

describe 'Documention', type: :model, group: :documentation do
  let(:instance_with_documentation) { TestDocumentable.new }

  let(:document1) { fixture_file_upload(Rails.root + 'spec/files/documents/tiny.pdf', 'application/pdf') }
  let(:document2) { fixture_file_upload(Rails.root + 'spec/files/documents/tiny.txt', 'text/plain') }

  let(:document_attributes) { 
    { document_file: document1 }
  }

  context 'associations' do
    specify 'has many documentation/#has_documentation?' do
      # test that the method notations exists
      expect(instance_with_documentation).to respond_to(:documents)
      expect(instance_with_documentation.documentation.size == 0).to be_truthy
    end
  end

  context 'methods' do
    specify '#has_documentation? (none)' do
      expect(instance_with_documentation).to respond_to(:has_documentation?)
      expect(instance_with_documentation.has_documentation?).to be_falsey
    end

    specify '#has_documentation? (1)' do
      expect(instance_with_documentation.documents << Document.new).to be_truthy
      expect(instance_with_documentation.has_documentation?).to be_truthy
      expect(instance_with_documentation.documentation.size == 1).to be_truthy
    end
  end

  context 'object with documentation' do
    context 'on destroy' do
      specify 'attached documentation is destroyed' do
        expect(Documentation.count).to eq(0)
        instance_with_documentation.documentation << FactoryGirl.build(:valid_documentation)
        instance_with_documentation.save
        expect(Documentation.count).to eq(1)
        expect(instance_with_documentation.destroy).to be_truthy
        expect(Documentation.count).to eq(0)
      end
    end
  end

  context 'create with nested documentation' do
    specify 'works by nesting document_attributes' do
      expect(TestDocumentable.create!(
        documentation_attributes: [ {document_attributes: document_attributes} ]
      )).to be_truthy
      expect(Document.count).to eq(1)
      expect(Documentation.count).to eq(1)
    end

    specify 'works with documents_attributes' do
      expect(TestDocumentable.create!(documents_attributes: [document_attributes])).to be_truthy
      expect(Document.count).to eq(1)
      expect(Documentation.count).to eq(1)
    end
  end

  context 'create with #document_array' do
    let(:data) {
      { '0' => document1, '1' => document2 }
    }

    specify '#document_array' do
      expect(instance_with_documentation).to respond_to('document_array=') 
    end

    specify 'succeeds' do
      instance_with_documentation.document_array = data
      expect(instance_with_documentation.save).to be_truthy
      expect(instance_with_documentation.documents.count).to eq(2)
      expect(instance_with_documentation.documents.first.id).to be_truthy 
    end
  end

end

class TestDocumentable < ActiveRecord::Base
  include FakeTable
  include Shared::Documentation
end