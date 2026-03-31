require "spec_helper"
require "#{Dir.pwd}/lib/krudmin/fields/base"
require "#{Dir.pwd}/lib/krudmin/fields/file"

describe Krudmin::Fields::File do
  let(:options) { {} }

  subject { described_class.new(:avatar, model, options) }

  describe "with an attached file" do
    let(:attachment) { double(attached?: true, filename: double(to_s: "photo.jpg"), content_type: "image/jpeg", byte_size: 12345) }
    let(:model) { double(avatar: attachment) }

    it "reports as attached" do
      expect(subject.attached?).to be true
    end

    it "returns the filename" do
      expect(subject.filename).to eq("photo.jpg")
    end

    it "detects image content type" do
      expect(subject.image?).to be true
    end

    it "returns the content type" do
      expect(subject.content_type).to eq("image/jpeg")
    end

    it "returns the byte size" do
      expect(subject.byte_size).to eq(12345)
    end

    it "displays filename as string" do
      expect(subject.to_s).to eq("photo.jpg")
    end
  end

  describe "with a non-image attachment" do
    let(:attachment) { double(attached?: true, filename: double(to_s: "report.pdf"), content_type: "application/pdf", byte_size: 50000) }
    let(:model) { double(avatar: attachment) }

    it "is not an image" do
      expect(subject.image?).to be false
    end

    it "returns the filename" do
      expect(subject.filename).to eq("report.pdf")
    end
  end

  describe "without an attachment" do
    let(:attachment) { double(attached?: false) }
    let(:model) { double(avatar: attachment) }

    it "reports as not attached" do
      expect(subject.attached?).to be false
    end

    it "displays dash" do
      expect(subject.to_s).to eq("-")
    end

    it "returns nil for filename" do
      expect(subject.filename).to be_nil
    end

    it "returns nil for content_type" do
      expect(subject.content_type).to be_nil
    end
  end

  describe "with nil data" do
    let(:model) { double(avatar: nil) }

    it "reports as not attached" do
      expect(subject.attached?).to be false
    end

    it "displays dash" do
      expect(subject.to_s).to eq("-")
    end
  end

  describe "options" do
    let(:model) { double(avatar: double(attached?: true, filename: double(to_s: "f.jpg"), content_type: "image/jpeg")) }

    context "multiple" do
      let(:options) { { multiple: true } }

      it "reports as multiple" do
        expect(subject.multiple?).to be true
      end

      it "returns array permitted attribute" do
        expect(subject.permitted_attribute).to eq({ avatar: [] })
      end
    end

    context "single" do
      it "reports as not multiple" do
        expect(subject.multiple?).to be false
      end

      it "returns symbol permitted attribute" do
        expect(subject.permitted_attribute).to eq(:avatar)
      end
    end

    context "accept" do
      let(:options) { { accept: "image/*" } }

      it "returns the accept option" do
        expect(subject.accept).to eq("image/*")
      end
    end

    context "direct_upload" do
      let(:options) { { direct_upload: true } }

      it "returns the direct_upload option" do
        expect(subject.direct_upload?).to be true
      end
    end

    context "max_file_size" do
      let(:options) { { max_file_size: 5.megabytes } }

      it "returns the max_file_size option" do
        expect(subject.max_file_size).to eq(5.megabytes)
      end
    end
  end

  describe "search" do
    it "returns nil for search config (not searchable)" do
      expect(described_class.search_config_for(:avatar)).to be_nil
    end
  end

  describe "parse" do
    let(:model) { double(avatar: nil) }

    it "passes the value through" do
      uploaded = double("uploaded_file")
      expect(subject.parse(uploaded)).to eq(uploaded)
    end
  end
end
