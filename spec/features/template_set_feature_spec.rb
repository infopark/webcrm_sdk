require 'spec_helper'

describe 'template set features' do
  let(:template_set) { Crm::TemplateSet.singleton }
  let(:now) { Time.now.utc.xmlschema }

  describe 'singleton' do
    it 'returns the TemplateSet singleton' do
      expect(template_set).to be_a(Crm::TemplateSet)
      expect(template_set.version).to be >= 0
      expect(template_set.templates).to have_key('password_request_email_from')
    end
  end

  describe 'update' do
    let!(:outdated_template_set) { Crm::TemplateSet.singleton }

    it 'updates under certain conditions' do
      expect {
        template_set.update(does_not_exist: '')
      }.to raise_error(Crm::Errors::InvalidKeys) do |error|
        expect(error.validation_errors.first['attribute']).to eq('does_not_exist')
      end

      # update template set
      old_version = template_set.version
      template_set.update(templates: {'foo' => nil})
      expect(template_set.templates['foo']).to be_nil
      expect(template_set.version).to eq(old_version + 1)

      template_set.update(templates: {'foo' => 'bar'})
      expect(template_set.templates['foo']).to eq('bar')
      expect(template_set.version).to eq(old_version + 2)

      expect(Crm::TemplateSet.singleton.templates['foo']).to eq('bar')

      # optimistic locking for update
      expect{
        outdated_template_set.update(templates: {foo: 'change again'})
      }.to raise_error(Crm::Errors::ResourceConflict)
    end
  end

  describe 'changes' do
    let(:random_change) { SecureRandom.hex(16) }

    before do
      template_set.update(templates: {foo: random_change})
    end

    it 'looks for changes' do
      changes = template_set.changes

      my_change = changes.detect do |change|
        change.details['templates.foo'].after == random_change
      end
      expect(my_change).to be_present
      expect(my_change.changed_at).to be_a(Time)
      expect(my_change.changed_by).to eq('root')

      detail = my_change.details['templates.foo']
      expect(detail.before).to_not eq(random_change)
      expect(detail.after).to eq(random_change)
    end
  end

  describe 'render_preview' do
    let(:contact) {
      Crm::Contact.create({
        last_name: 'Smith',
        gender: 'N',
        language: 'en',
      })
    }
    let(:templates) {{ greeting: "Dear {{contact.last_name}}, {{foo}}" }}

    it 'renders a preview with combined templates' do
      expect(template_set.render_preview(templates: templates, context: {
        contact: contact.id,
        foo: 'welcome!'
      }
      )).to include({
        'greeting' => 'Dear Smith, welcome!',
      })
    end

    it 'detects syntax errors' do
      expect {
        template_set.render_preview(templates: {broken: 'Hello {{'})
      }.to raise_error(Crm::Errors::InvalidValues) do |error|
        expect(error.validation_errors.first['code']).to eq('liquid_syntax_error')
      end
    end
  end
end
