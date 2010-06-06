EncodedAttachment
=================

This is the bestest and certainly the easiest way to handle file uploads/downloads to [Paperclip](http://github.com/thoughtbot/paperclip)-using Active Record-backed resources using Active Resource.

Rather than trying to create a multipart form submission, it just embeds the file's binary data in the Active Record model's <tt>to_xml</tt>. You can also embed binary data into XML to POST or PUT using Active Resource. These tags will automatically be parsed by Active Record and Active Resource to create files.


Usage
-----

In a Rails application:

    # Gemfile
    gem "encoded_attachment", :git => "git://github.com/nragaz/encoded_attachment"
    
This will load the class methods into both ActiveRecord and ActiveResource. Nothing will really "happen" unless you use the methods described below in your models.

Note that the ActiveRecord code is designed to be used with [Paperclip](http://github.com/thoughtbot/paperclip).

Outside of Rails, the gem can be required directly. It will load itself into ActiveRecord::Base and/or ActiveResource::Base if they have already been loaded. (You can manually include the needed methods using <tt>EncodedAttachment.setup_activerecord</tt> and <tt>EncodedAttachment.setup_activeresource</tt> if you really want to require this gem first.)


Functionality
=============

Active Record
-------------

Adds a class method called <tt>encode_attachment_in_xml</tt> to Active Record that can be used alongside Paperclip's <tt>has_attached_file</tt> to automatically generate useful and usable binary XML tags for the attachment's original file by wrapping <tt>to_xml</tt>.

These tags will not be generated on new or destroyed records (because the Paperclip file needs to be saved to disk before it is encoded). You can disable file generation at any time using <tt>to_xml(:include_attachments => false)</tt>.

Note that by default, the XML will *not* include Paperclip attributes such as <tt>attachment_file_name</tt>, <tt>attachment_file_size</tt>, <tt>attachment_content_type</tt> and <tt>attachment_updated_at</tt>. The file name and content type are in the XML tag as attributes. Using <tt>to_xml(:include_attachments => false)</tt> will restore these attributes to your XML.


Active Resource
---------------

Adds a class method called <tt>has_encoded_attachment</tt> to Active Resource that generates a schema for the file's attributes and then embeds the file's binary content in <tt>to_xml</tt> if the file has been changed or the record is new.

You can force embedding using <tt>to_xml(:include_attachments => true)</tt>. File setters include <tt>file=</tt> and <tt>file_path=</tt>. MIME types are detected based on the file name.


Downloading Files using URLs
----------------------------

To avoid transmitting huge XML files (particularly in index actions), you can choose to have Active Record send the URL of the file instead of the encoded path using:

    encode_attachment_in_xml :attachment_name, :send_urls => true, :root_url => "http://yourdomain"
    
<tt>:root_url</tt> is optional.

You can force the file's binary data to be embedded using <tt>to_xml(:encode_attachments => true)</tt>.

The URL will be downloaded separately by the Active Resource object using the same protocol settings as its native connection (e.g. authentication will be preserved).

There are some limitations to this: your file URL must be on the same domain as the resource's base URL, and the URL must include the file name and extension (e.g. "/images/*rails.png*") for MIME type and file name detection.

There is no support for Active Resource submitting a file URL back to Active Record. Using the <tt>file=</tt> or <tt>file_path=</tt> methods on your Active Resource object will obliterate the <tt>file_url</tt> attribute so that it doesn't appear in your PUT.

Potential use cases include:

    class MyModel < ActiveRecord::Base
        encode_attachment_in_xml :my_file, :send_urls => true, :root_url => "http://yourdomain"
    end
    
    class MyModelsController < ActionController::Base
        def index
            MyModel.all.to_xml # sends URLs
        end
    
        def show
            MyModel.find(params[:id]).to_xml(:encode_attachments => true) # sends encoded files
        end
    end


Example
=======

In Active Record:

    class MyModel < ActiveRecord::Base
        has_attached_file        :pdf
        encode_attachment_in_xml :pdf
    end

    my_model = MyModel.create(:pdf => File.open('example.pdf'))
    my_model.to_xml => '<my-model>\n<pdf type="file" name="example.pdf" content-type="application/pdf">[binary data]</pdf>\n</my-model>'


In Active Resource:

    class MyModelResource < ActiveResource::Base
        self.element_name = "my_model"

        has_encoded_attachment :pdf
    end

    my_model_resource = MyModelResource.new.from_xml(my_model.to_xml)
    my_model_resource.pdf # => <StringIO> containing binary data
    my_model_resource.save_pdf_as("my_downloaded_file.pdf")

    my_model_resource.pdf = File.open('example-downloaded.pdf')
    my_model_resource.pdf_file_name # => "example_downloaded.pdf"
    my_model_resource.pdf_content_type # => "application/pdf"
