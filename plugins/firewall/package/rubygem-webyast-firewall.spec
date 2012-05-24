# spec file for package webyast-firewall (Version 0.1)
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#

# norootforbuild
Name:           rubygem-webyast-firewall
Version:        0.3.1
Release:        0
%define mod_name webyast-firewall
%define mod_full_name %{mod_name}-%{version}
#
Group:          Productivity/Networking/Web/Utilities
License:        GPL-2.0	
#
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  rubygems_with_buildroot_patch
%rubygems_requires
BuildRequires:	webyast-base
BuildRequires:	rubygem-webyast-rake-tasks >= 0.2
BuildRequires:	webyast-base-testsuite
BuildRequires:	rubygem-restility
PreReq:	        webyast-base
PreReq:         rubygem-webyast-rake-tasks >= 0.2
%if 0%{?suse_version} == 0 || %suse_version > 1110
Requires:       yast2-core >= 2.18.10
%else
Requires:       yast2-core >= 2.17.30.1
%endif
Requires:       SuSEfirewall2
Summary:        WebYaST - Firewall management service
Source:         %{mod_full_name}.gem
Source1:        org.opensuse.yast.modules.yapi.firewall.policy
Source2:        FIREWALL.pm

%package doc
Summary:        RDoc documentation for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%package testsuite
Summary:        Test suite for %{mod_name}
Group:          Development/Languages/Ruby
Requires:       %{name} = %{version}

%description
WebYaST - Plugin provides REST based interface to handle firewall settings.
Authors:
--------
    Martin Kudlvasr<mkudlvasr@novell.com>

%description testsuite
This package contains complete testsuite for webyast-firewall package.
It's only needed for verifying the functionality of the module and it's not
needed at runtime.

%description doc
Documentation generated at gem installation time.
Usually in RDoc and RI formats.

%prep

%build

%check

# run the testsuite
%webyast_run_plugin_tests

%install
%gem_install %{S:0}

# Policies
mkdir -p $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}
install -m 0644 %SOURCE1 $RPM_BUILD_ROOT/usr/share/%{webyast_polkit_dir}

#YaPI
mkdir -p $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/
cp %{SOURCE2} $RPM_BUILD_ROOT/usr/share/YaST2/modules/YaPI/

%webyast_build_restdoc public/firewall/restdoc

# remove empty public
rm -rf $RPM_BUILD_ROOT/%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/public

%webyast_build_plugin_assets

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%post
#
# granting all permissions for root
#
/usr/sbin/grantwebyastrights --user root --action grant > /dev/null ||:
/usr/sbin/grantwebyastrights --user %{webyast_user} --action grant > /dev/null ||:

%webyast_update_assets

%postun
%webyast_remove_assets

%files 
%defattr(-,root,root)
%{_libdir}/ruby/gems/%{rb_ver}/cache/%{mod_full_name}.gem
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/
%exclude %{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test
%{_libdir}/ruby/gems/%{rb_ver}/specifications/%{mod_full_name}.gemspec

# precompiled assets
%dir %{webyast_dir}/public/assets
%{webyast_dir}/public/assets/*

# restdoc documentation
%dir %{webyast_dir}/public/firewall
%{webyast_dir}/public/firewall/restdoc

%dir /usr/share/%{webyast_polkit_dir}
%attr(644,root,root) %config /usr/share/%{webyast_polkit_dir}/org.opensuse.yast.modules.yapi.firewall.policy

# YaPI dir
%dir /usr/share/YaST2/
%dir /usr/share/YaST2/modules/
%dir /usr/share/YaST2/modules/YaPI/
/usr/share/YaST2/modules/YaPI/FIREWALL.pm

%files doc
%defattr(-,root,root,-)
%doc %{_libdir}/ruby/gems/%{rb_ver}/doc/%{mod_full_name}/

%files testsuite
%defattr(-,root,root,-)
%{_libdir}/ruby/gems/%{rb_ver}/gems/%{mod_full_name}/test

%changelog