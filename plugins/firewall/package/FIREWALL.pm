package YaPI::FIREWALL;

use strict;
use YaST::YCP qw(:LOGGING);
use YaPI;
use Data::Dumper;

# --------------- imported modules
YaST::YCP::Import ("SuSEFirewall");
YaST::YCP::Import ("SuSEFirewallServices");
# --------------------------------

our $VERSION            = '1.0.0';
our @CAPABILITIES       = ('SLES11');
our %TYPEINFO;

# Return a boolean value indicating, whether a firewall is running and
# a list of services with their translated name and a boolean value indicating whether
# they should be allowed or not (in the external zone).
BEGIN{$TYPEINFO{Read} = ["function", ["map", "string", "any"]];
}

sub Read {
  my $self = shift;
  SuSEFirewall->Read();
  my $status  = YaST::YCP::Boolean( SuSEFirewall->GetEnableService () );
  y2milestone "YaPI::FIREWALL::status -> '".$status."'";
  my $known_services = SuSEFirewallServices->GetSupportedServices();
  my @service_ids = keys %$known_services;
  my $service_zones = SuSEFirewall->GetServices(\@service_ids);
  my $mkService = mkServiceGenerator($known_services, $service_zones, "EXT");
  my @services = map($mkService->($_),@service_ids);
  y2milestone "YaPI::FIREWALL::mkService -> '".($mkService->($service_ids[0]))."'";
  my %ret = ('use_firewall' => $status, 
             'services'     => \@services
            );
  return \%ret;
}

sub mkServiceGenerator {
  my($service_names,$service_zones,$zone) = @_;
  my $generator = sub { my $service_id = shift;
                       { 'id'      => $service_id,
                         'name'    => $service_names->{$service_id},
                         'allowed' => YaST::YCP::Boolean( $service_zones->{$service_id}->{$zone} )
                       }
                      };
  return $generator;
}


