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

sub findTests() : Test(3)
{
    my $self = shift;
        
    my $testlists = Testing::TestLists->new(cimeroot => "./t/mocks_TestLists/mockcimeroot");
    
    my $component = undef;
    my %params = ( machine => 'yellowstone' );
    my @cimetestlist = $testlists->findTests( $component, \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{machine} eq 'yellowstone');
    }
     %params = ( compiler => 'intel', machine => 'yellowstone' );
    @cimetestlist = $testlists->findTests( $component, \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{machine} eq 'yellowstone');
        ok($ct->{compiler} eq 'intel');
    }
    %params = ( testmods => 'allactive', compiler => 'intel', machine => 'yellowstone' );
    @cimetestlist = $testlists->findTests( $component, \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{machine} eq 'yellowstone');
        ok($ct->{compiler} eq 'intel');
        ok($ct->{testmods} eq 'allactive');
    }
}

sub findTestsForComp() : Test(3)
{
    my $self = shift;
    
    my $testlists = Testing::TestLists->new(cimeroot => "./t/mocks_TestLists/mockcimeroot");
    
    my %params = ( machine => 'yellowstone' );
    my @cimetestlist = $testlists->findTestsForComp('allactive', \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{machine} eq 'yellowstone');
    }


    %params = ( compset => 'B1850', machine => 'yellowstone', compiler => 'intel');
    @cimetestlist = $testlists->findTestsForComp('allactive', \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{compset} eq 'B1850');
        ok($ct->{machine} eq 'yellowstone');
        ok($ct->{compiler} eq 'intel');
    }
    %params = (  machine => 'yellowstone', compiler => 'intel');
    @cimetestlist = $testlists->findTestsForComp('allactive', \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{machine} eq 'yellowstone');
        ok($ct->{compiler} eq 'intel');
    }
    %params = (  category => 'prebeta');
    @cimetestlist = $testlists->findTestsForComp('allactive', \%params);
    foreach my $ct(@cimetestlist)
    {
        ok($ct->{category} eq 'prebeta');
    }
    %params = ();
    @cimetestlists = $testlists->findTestsForComp('allactive', \%params);
}

1;
