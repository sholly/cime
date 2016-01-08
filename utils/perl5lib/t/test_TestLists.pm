#!/usr/bin/env perl 
#
package test_TestLists;

use Data::Dumper;
use Test::More;
use Test::Exception;
use lib '.';
use Testing::TestLists;

use parent qw(Test::Class);

sub startup: Test(startup => 0)
{
    my $self = shift;
}

sub shutdown: Test(shutdown => 0)
{
    my $self = shift;
}

sub setup : Test(setup => 0)
{
    my $self = shift;
}

sub teardown : Test(setup => 0) 
{
    my $self = shift;
}

sub test_new() : Test(1)
{
    my $self = shift;
    
    my $testlists = Testing::TestLists->new(cimeroot => "./t/mocks_TestLists/mockcimeroot");
    isa_ok($testlists, "Testing::TestLists");
}

sub findTestsForFile() : Test(3)
{
    my $self = shift;
    
    my $testlists = Testing::TestLists->new(cimeroot => "./t/mocks_TestLists/mockcimeroot");
    
    #my %params = ( machine => 'yellowstone' );
    #my @cimetestlists = $testlists->findTestsForFile($testlists->{allactive}, \%params);
    #print Dumper \@cimetestlists;


    #%params = ( compset => 'B1850', machine => 'yellowstone', compiler => 'intel');
    #@cimetestlists = $testlists->findTestsForFile($testlists->{allactive}, \%params);
    %params = (  machine => 'yellowstone', compiler => 'intel');
    @cimetestlists = $testlists->findTestsForFile($testlists->{allactive}, \%params);
}
1;
