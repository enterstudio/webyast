#
# patch_test.rb
#
# Test 'Patch' model
#
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.join(File.dirname(__FILE__), "..", "packagekit_stub")
require 'patch'

def read_test_data(name)
  File.readlines File.join(File.dirname(__FILE__), "data", name)
end

class PatchTest < ActiveSupport::TestCase

  def setup
    #
    # Patch model stubbing
    #
    
    @pk_stub = PackageKitStub.new
    @transaction, @packagekit = PackageKit.connect
    
    # avoid accessing the rpm db
    Patch.stubs(:mtime).returns(Time.now)

    Patch.stubs(:open_subprocess).returns(nil)

  end
  
  def test_available_patches

#    @transaction.stubs(:GetUpdates).with("NONE").returns(true)

    # Available updates in PackageKit format
    #
    # Format:
    # [ line1, line2, line3 ]
    # line1: <kind>
    # line2: <name>;<id>;<arch>;<repo>
    # line3: <summary>
    #
    rset = PackageKitResultSet.new "Package", :info => :s, :id => :s, :summary => :s
    rset << [ 'important', 'update-test-affects-package-manager;847;noarch;updates-test', 'update-test: Test updates for 11.2' ]
    rset << [ 'security', 'update-test;844;noarch;updates-test', 'update-test: Test update for 11.2' ]
    @pk_stub.result = rset
    
    # Mock 'GetUpdates' by defining it
    m = DBus::Method.new("GetUpdates")
    m.from_prototype("in kind:s")
    @transaction.methods[m.name] = m
    class <<@transaction
      def GetUpdates kind
	# dummy !
      end
    end

    patches = Patch.find(:available)
    assert_equal 2, patches.size
    patch = patches.first
    assert_equal "847", patch.resolvable_id
  end

  SCRIPT_OUTPUT_ERROR = read_test_data('patch_test-script_error.out')

  def test_available_patches_background_mode_error

    Patch.stubs(:read_subprocess).returns(*SCRIPT_OUTPUT_ERROR)
    # return EOF when all lines are read
    Patch.stubs(:eof_subprocess?).returns(*(Array.new(SCRIPT_OUTPUT_ERROR.size, false) << true))
    
    # note: Patch.find(:available, {:background => true})
    # cannot be used here, Threading support in test mode doesn't work :-(
    patches = Patch.subprocess_find(:available)

    assert_equal PackageKitError, patches.class
  end

  SCRIPT_OUTPUT_OK = read_test_data('patch_test-script_ok.out')

  def test_available_patches_background_mode_ok
    Patch.stubs(:read_subprocess).returns(*SCRIPT_OUTPUT_OK)

    # return EOF when all lines are read
    Patch.stubs(:eof_subprocess?).returns(*(Array.new(SCRIPT_OUTPUT_OK.size, false) << true))

    # note: Patch.find(:available, {:background => true})
    # cannot be used here, Threading support in test mode doesn't work :-(
    patches = Patch.subprocess_find(:available)

    assert_equal 4, patches.size
    assert_equal 1579, patches.first.resolvable_id
    assert_equal 'slessp0-openslp', patches.first.name
  end
  
end
