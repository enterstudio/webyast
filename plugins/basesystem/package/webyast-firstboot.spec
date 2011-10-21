#
# spec file for package webyast-firstboot (Version 0.1)
#
# Copyright (c) 2008-09 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           webyast-firstboot
Provides:       WebYaST(org.opensuse.yast.modules.basesystem)
Provides:       webyast-firstboot-ws = %{version}
Obsoletes:      webyast-firstboot-ws < %{version}
PreReq:         webyast-base
License:        GPL-2.0	
Group:          Productivity/Networking/Web/Utilities
URL:            http://en.opensuse.org/Portal:WebYaST
Autoreqprov:    on
Version:        0.3.0
Release:        0
Summary:        WebYaST - initial settingsvice
Source:         www.tar.bz2
Source1:        basesystem.yml
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch

BuildRequires:  webyast-base-testsuite
BuildRequires:	rubygem-test-unit rubygem-mocha

#
%define plugin_name basesystem
%define plugin_dir %{webyast_dir}/vendor/plugins/%{plugin_name}
#

%package testsuite
Group:    Productivity/Networking/Web/Utilities
Requires: %{name} = %{version}
Requires: webyast-base-testsuite
Provides:  webyast-firstboot-ws-testsuite = %{version}
Obsoletes: webyast-firstboot-ws-testsuite < %{version}
Summary:  Testsuite for webyast-firstboot package

%description
WebYaST - Plugin for the first run of system configuration.

Authors:
--------
    Josef Reidinger <jreidinger@suse.cz>
    Martin Kudlvasr <mkudlvasr@suse.cz>

%description testsuite
This package contains complete testsuite for webyast-firstboot package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%prep
%setup -q -n www

%build

%check
# run the testsuite
%webyast_check

%install

#
# Install all web and frontend parts.
#
mkdir -p $RPM_BUILD_ROOT%{webyast_vardir}%{plugin_name}

mkdir -p $RPM_BUILD_ROOT%{plugin_dir}
cp -a * $RPM_BUILD_ROOT%{plugin_dir}/
rm -f $RPM_BUILD_ROOT%{plugin_dir}/COPYING

mkdir -p $RPM_BUILD_ROOT/etc/webyast/
cp %SOURCE1 $RPM_BUILD_ROOT/etc/webyast/

%clean
rm -rf $RPM_BUILD_ROOT


%files 
%defattr(-,root,root)
%dir %{webyast_dir}
%dir %{webyast_dir}/vendor
%dir %{webyast_dir}/vendor/plugins
%dir %{plugin_dir}
%dir %{plugin_dir}/doc

#var dir to store basesystem status
%dir %attr (-,%{webyast_user},root) %{webyast_vardir}
%dir %attr (-,%{webyast_user},root) %{webyast_vardir}/%{plugin_name}
%dir /etc/webyast/

%config /etc/webyast/basesystem.yml

%{plugin_dir}/README
%{plugin_dir}/Rakefile
%{plugin_dir}/init.rb
%{plugin_dir}/install.rb
%{plugin_dir}/uninstall.rb
%{plugin_dir}/app
%{plugin_dir}/config
%{plugin_dir}/doc/README_FOR_APP

%doc COPYING

%files testsuite
%defattr(-,root,root)
%{plugin_dir}/test

%changelog
