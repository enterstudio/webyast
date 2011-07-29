#
# spec file for package webyast-registration
#
# Copyright (c) 2009 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-registration
Provides:       WebYaST(org.opensuse.yast.modules.registration.registration)
Provides:       WebYaST(org.opensuse.yast.modules.registration.configuration)
Provides:       yast2-webservice-registration = %{version}
Obsoletes:      yast2-webservice-registration < %{version}
PreReq:         yast2-webservice, yast2-registration, rubygem-gettext_rails
License:        GPL-2.0 
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.2.5
Release:        0
Summary:        WebYaST - Registration
Source:         www.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Recommends:     openssl-certs

BuildRequires:  webyast-base-testsuite rubygem-gettext_rails
BuildRequires:	rubygem-test-unit rubygem-mocha

# YaST2/modules/YSR.pm  
%if 0%{?suse_version} == 0 || 0%{?suse_version} > 1120
# non-suse, factory, and YaST:HEAD
Requires:       yast2-registration >= 2.19.7
%else
%if 0%{?suse_version} == 1120
Requires:       yast2-registration >= 2.18.5
%endif
%if 0%{?suse_version} <= 1110
# SLE11 and 11.1
Requires:       yast2-registration >= 2.17.35
%endif
%endif
#
%define plugin_name registration
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Summary:  Testsuite for webyast-registration package

%description
WebYaST - Plugin providing REST based interface for the system registration at NCC, SMT or SLMS

Authors:
--------
    J. Daniel Schmidt <jdsn@novell.com>
    Stefan Schubert <schubi@novell.com>

%description testsuite
This package contains complete testsuite for webyast-registration package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

export RAILS_PARENT=%{webyast_dir}
env LANG=en rake makemo

%check
# run the testsuite
%webyast_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

# remove .po files (no longer needed)
rm -rf $RPM_BUILD_ROOT/%{plugin_dir}/po

# search locale files
%find_lang webyast-registration

%clean
rm -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root and webyast
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null

%files -f webyast-registration.lang
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc

%dir %{plugin_dir}/locale
%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/lib
%{plugin_dir}/doc/README_FOR_APP

%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog