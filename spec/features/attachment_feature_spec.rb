require 'spec_helper'
require 'rest-client'

describe 'attachment features' do
  before(:all) { CrmSetup.define_support_case }

  it 'allows adding attachments to comments' do
    # create with file
    activity = Crm::Activity.create({
      type_id: 'support-case',
      state: 'created',
      title: 'attachment test',
      comment_notes: 'My README.md',
      comment_attachments: [File.new('README.md')],
    })
    readme_attachment = activity.comments.first.attachments.first
    download_response = RestClient.get(readme_attachment.download_url)
    expect(download_response.body).to eq(File.read('README.md'))
    expect(download_response.headers[:content_type]).to eq('text/plain')

    # update with file
    activity_to_be_updated = Crm::Activity.create({
      type_id: 'support-case',
      state: 'created',
      title: 'attachment update test',
    })
    activity_to_be_updated.update({
      comment_notes: 'My updated README.md',
      comment_attachments: [File.new('README.md')],
    })
    readme_attachment = activity_to_be_updated.comments.first.attachments.first
    download_response = RestClient.get(readme_attachment.download_url)
    expect(download_response.body).to eq(File.read('README.md'))
    expect(download_response.headers[:content_type]).to eq('text/plain')

    # upload another file manually
    permission = Crm::Core::AttachmentStore.generate_upload_permission

    params = {}
    params.merge!(permission.fields)
    params.merge!(:file => File.new('LICENSE'))
    response = RestClient.post(permission.url, params)
    expect(response.code).to be_between(200, 299).inclusive

    # attach file to comment
    activity.update({
      comment_notes: "See the attached file",
      comment_attachments: ["#{permission.upload_id}/LICENSE"]
    })
    license_attachment = activity.comments.last.attachments.first
    expect(license_attachment.id).to match(/LICENSE$/)

    # read attached file via download_url
    download_url = license_attachment.download_url
    expect(RestClient.get(download_url).body).to eq(File.read('LICENSE'))

    # read attached file via generate_download_url
    download_url = Crm::Core::AttachmentStore.generate_download_url(license_attachment.id)
    expect(RestClient.get(download_url).body).to eq(File.read('LICENSE'))

    # access comments via #attributes
    license_attachment = activity.attributes[:comments].last.attachments.first
    expect(license_attachment.id).to match(/LICENSE$/)
  end
end
