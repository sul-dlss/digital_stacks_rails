require 'rails_helper'

describe User do
  describe 'abilities' do
    subject(:ability) { Ability.new(user) }
    let(:user) { nil }
    let(:file) { StacksFile.new.tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) } }
    let(:image) { StacksImage.new.tap { |x| allow(x).to receive(:rights_xml).and_return(rights_xml) } }
    let(:thumbnail) { StacksImage.new(region: 'full', size: '!400,400') }
    let(:tile) { StacksImage.new(region: '0,0,100,100', size: '256,256') }
    let(:rights_xml) { '' }

    before do
      allow_any_instance_of(StacksImage).to receive(:rights_xml).and_return(rights_xml)
    end

    context 'webauth user' do
      let(:user) { User.new(id: 'a', webauth_user: true, ldap_groups: %w(stanford:stanford)) }

      context 'with an unrestricted file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with an world-readable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with an stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with a tile of a no-download file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group rule="no-download">Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, image) }
      end
    end

    context 'app user' do
      let(:user) { User.new(id: 'a', app_user: true) }

      context 'with an unrestricted file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world />
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with an world-readable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <world />
                  <agent>a</agent>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with an stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
                <agent>a</agent>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with an agent-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <agent>a</agent>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:download, file) }
        it { is_expected.to be_able_to(:download, image) }
      end

      context 'with a tile of a no-download file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <agent rule="no-download">a</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, image) }
      end
    end

    context 'anonymous user' do
      context 'with an stanford-only file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <group>Stanford</group>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        it { is_expected.not_to be_able_to(:download, file) }
        it { is_expected.not_to be_able_to(:download, image) }
      end

      context 'with a thumbnail of an unreadable file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end

        it { is_expected.to be_able_to(:read, thumbnail) }
        it { is_expected.not_to be_able_to(:read, image) }
      end

      context 'with a tile of a no-download file' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
            <access type="read">
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
          </rightsMetadata>
          EOF
        end
        it { is_expected.to be_able_to(:read, tile) }
        it { is_expected.not_to be_able_to(:read, image) }
      end
    end
  end

  describe '#stanford?' do
    context 'with a webauth user in the appropriate workgroups' do
      it 'is a stanford user' do
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:stanford))).to be_stanford
      end
    end

    context 'with just a webauth user' do
      it 'is not a stanford user' do
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:sponsored))).not_to be_stanford
      end
    end
  end
end
