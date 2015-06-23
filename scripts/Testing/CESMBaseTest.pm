#!/usr/bin/env perl 
#==============================================================================
#==============================================================================

use strict;
use warnings;

package CESMBaseTest;
use File::Copy;
use POSIX qw(strftime);
use lib '.';

sub new
{
	my ($class, %params) = @_;
	my $self = {};
	

	bless $self, $class;
}

sub preTest()
{
	my $self = shift;
	$self->{'mach'} = qx( ./xmlquery MACH -value);
	$self->{'ccsm_machdir'} = qx( ./xmlquery CCSM_MACHDIR -value);
	$self->{'cimeroot'} = qx( ./xmlquery CIMEROOT -value);
	$self->{'rundir'} = qx( ./xmlquery RUNDIR -value);
	$self->{'exeroot'} = qx( ./xmlquery EXEROOT -value);
	$self->{'libroot'} = qx( ./xmlquery LIBROOT -value);
	$self->{'scriptsroot'} = qx( ./xmlquery SCRIPTSROOT -value);
	$self->{'dout_s_root'} = qx( ./xmlquery DOUT_S_ROOT -value);
	$self->{'caseroot'} = qx( ./xmlquery CASEROOT -value);
	$self->{'case'} = qx( ./xmlquery CASE -value);
	$self->{'casebaseid'} = qx( ./xmlquery CASEBASEID -value);
	$self->{'testcase'} = qx( ./xmlquery TESTCASE -value);
	$self->{'test_argv'} = qx( ./xmlquery TEST_ARGV -value);
	$self->{'test_testid'} = qx( ./xmlquery TEST_TESTID -value);
	$self->{'baselineroot'} = qx( ./xmlquery BASELINEROOT -value);
	$self->{'basegen_case'} = qx( ./xmlquery BASEGEN_CASE -value);
	$self->{'basecmp_case'} = qx( ./xmlquery BASECMP_CASE -value);
	$self->{'basegen_name'} = qx( ./xmlquery BASEGEN_NAME -value);
	$self->{'basecmp_name'} = qx( ./xmlquery BASECMP_NAME -value);
	$self->{'generate_baseline'} = qx( ./xmlquery GENERATE_BASELINE -value);
	$self->{'compare_baseline'} = qx( ./xmlquery COMPARE_BASELINE -value);
	$self->{'cleanup'} = qx( ./xmlquery CLEANUP -value);
	$self->{'ccsm_baseline'} = qx( ./xmlquery CCSM_BASELINE -value);
	$self->{'casetools'} = qx( ./xmlquery CASETOOLS -value);
	$self->{'compiler'} = qx( ./xmlquery COMPILER -value);
	$self->{'mpilib'} = qx( ./xmlquery MPILIB -value);

	if($self->'generate_baseline'} eq 'TRUE')
	{
		$self->{'basegen_dir'} = $self->{'baselineroot'} . "/" . $self->{'basegen_case'};	
	}
	else
	{
		$self->{'basegen_dir'} = "";
	}
	
	if($self->{'basecmp_dir'} eq 'TRUE')
	{
        $self->{'basecmp_dir'} = $self->{'baselineroot'} . "/" . $self->{'basecmp_case'};
	}
	else
	{
		$self->{'basecmp_dir'} = "";
	}
	
	# set up TestStatus, TestStatus.log, etc locations
	$self->{'casestatus'} = $self->{'caseroot'} . "/CaseStatus";
	$self->{'teststatus_out'} = $self->{'caseroot'} . "/TestStatus";
	$self->{'teststatus_log'} = $self->{'caseroot'} . "/TestStatus.log";
	$self->{'teststatus_out_nlcomp'} = $self->{'caseroot'} . "/TestStatus.nlcomp";

	open my $TESTOUT, ",", $self->{'teststatus_out'} or die "cannot open $self->{'teststatus_out'}";
	print $TESTOUT " RUN $self->{'case'}\n";
	close $TESTOUT;

	$self->{'startdate'} = strftime("%Y-%m-%d %H:%M:%S", localtime);
	$self->{'teststart'} = strftime("%Y-%m-%d %H:%M:%S", localtime);
	$self->{'teststart_sec'} = time;
	

}

sub runTest()
{

}

sub postTest()
{

}


