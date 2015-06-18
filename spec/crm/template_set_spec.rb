require 'spec_helper'

module Crm

describe TemplateSet do
  let(:item) { TemplateSet.new({}) }
  let(:now) { Time.now.utc.xmlschema }

  it 'is a BasicResource' do
    expect(item).to be_a Core::BasicResource
  end

  it 'is ChangeLoggable' do
    expect(item).to be_a Core::Mixins::ChangeLoggable
  end

  describe '#inspect' do
    it 'is Inspectable' do
      expect(item).to be_a Core::Mixins::Inspectable
    end

    it 'prints interesting information' do
      expect(item.inspect).to include(%|>|)
    end
  end

  describe '#singleton' do
    it 'loads the attributes from server' do
      expect(Core::RestApi.instance).to receive(:get).with('template_set').and_return({'foo' => 'something'})
      expect(TemplateSet.singleton.foo).to eq('something')
    end

    it 'returns an instance of the TemplateSet singleton' do
      expect(Core::RestApi.instance).to receive(:get).and_return({})

      expect(TemplateSet.singleton).to be_a(TemplateSet)
    end
  end

  describe '#update' do
    let(:resource) {
      TemplateSet.new({
        'templates' => {
          'foo' => 'old value',
        },
        'version' => 2,
      })
    }

    it 'updates the resource' do
      expect(Core::RestApi.instance).to receive(:put).with(
        'template_set', {
          'templates' => {'foo' => 'new value'}
        }, {'If-Match' => 2}
      ).and_return({
        'templates' => {
          'foo' => 'new value',
        },
        'updated_at' => now,
      })
      expect(resource.update({'templates' => {'foo' => 'new value'}})).to be(resource)

      expect(resource.templates['foo']).to eq('new value')
      expect(resource.updated_at).to eq(now)
    end
  end

  describe '#render_preview' do
    it 'renders a preview for the given and stored templates' do
      expect(Core::RestApi.instance).to receive(:post).with('template_set/render_preview', {
        'templates' => {
          'greetings' => 'Dear {{contact.first_name}}.',
        },
        'context' => {
          'contact' => '23',
          'foo' => 'bar',
        },
      }).and_return({
        'greetings' => 'Dear John.',
        'stored_template' => 'Something',
      })
      expect(item.render_preview(
        templates: {'greetings' => 'Dear {{contact.first_name}}.'},
        context: {'contact' => '23', 'foo' => 'bar'}
      )).to eq({
        'greetings' => 'Dear John.',
        'stored_template' => 'Something',
      })
    end

    context 'when no parameters are given' do
      it 'renders a preview for the stored templates with no context' do
        expect(Core::RestApi.instance).to receive(:post).with('template_set/render_preview', {
          'templates' => {},
          'context' => {},
        }).and_return({
          'stored_template' => 'Something',
        })
        expect(item.render_preview).to eq({
          'stored_template' => 'Something',
        })
      end
    end
  end
end

end
