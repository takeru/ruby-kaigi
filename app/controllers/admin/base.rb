class Admin::Base < ApplicationController
  def local_request?
    true
  end
end
