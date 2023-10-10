# frozen_string_literal: true

# add active class to a navbar link if the request begins with the correct path
module NavbarHelper
  def nav_active(request, path)
    'active' if request.path.starts_with?(path)
  end
end

