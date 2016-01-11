package Testing::TestLists;
use Exporter;
use Data::Dumper;
use lib '.';
require Testing::CIMETest;
use Cwd;
#my @ISA = qw(Exporter);
#my @EXPORTOK = qw(findTestsForCase);
BEGIN
{
	use vars qw( $VERSION @ISA );
	$VERSION = '0.01';
	@ISA     = qw();
}
	
#-----------------------------------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------------------------------
use strict;

use XML::LibXML;

sub new
{
	my ($class, %params) = @_;

	my $self = {
		cimeroot => $params{'cimeroot'} || undef,
	};
	if(! defined $self->{cimeroot})
	{
		# TODO figure out a more appropriate method of erroring out..
	}
    # set up paths to the allactive and component test lists
    # TODO Jim's refactor will make this easier, for now, implement 
    # such that all we are concerned about is CESM. 
    $self->{allactive} = $self->{cimeroot} . "/cime_config/cesm/allactive/testlist_allactive.xml";
    $self->{cam} = $self->{cimeroot} . "/../components/cam/cime_config/testdefs/testlist_cam.xml";
    $self->{cice} = $self->{cimeroot} . "/../components/cice/cime_config/testdefs/testlist_cam.xml";
    $self->{cism} = $self->{cimeroot} . "/../components/cism/cime_config/testdefs/testlist_cism.xml";
    $self->{clm} = $self->{cimeroot} . "/../components/clm/cime_config/testdefs/testlist_clm.xml";
    $self->{pop} = $self->{cimeroot} . "/../components/pop/cime_config/testdefs/testlist_pop.xml";
    $self->{rtm} = $self->{cimeroot} . "/../components/rtm/cime_config/testdefs/testlist_rtm.xml";
    my @components = ( "allactive", "cam", "cice", "cism", "clm", "pop", "rtm");
    $self->{components} = \@components;
	
	bless $self, $class;
    #print Dumper $self;
	return ($self);
}

#-----------------------------------------------------------------------------------------------
# find a set of tests in the file, given appropriate query options. 
# Arguments: hash of parameters to search on
# Returns a list of CIMETest objects. 
# # TODO: CIMETest is really a bad name for what are simple little data storage objects, 
# perhaps a better name is appropriate? 
#-----------------------------------------------------------------------------------------------
sub findTestsForFile()
{
    my $self = shift;
    my $filetoquery = shift;
    my $params = shift;
    
    my @cimetestlist;

    # The beginning of the XPATH query, we always want to search for '/testlist/test'
    my $query = "/testlist/test";
    # 
    # compset or testmods, add attribute search query options to the query. 
    my %outerfields = ( testname => 'name', grid => 'grid', compset => 'compset', 
                        testmods => 'testmods');
    my %innerfields = ( machine => 'name', compiler => 'compiler', category => 'category');

    # Create two hashes of the testlist xml attributes that are actually defined in the 
    # parameters for this file. 
    
    # Find out whether the testname, grid, compset, or testmods are defined in the
    # paramters, stash them in the definedouterfields hash.  This way we can dynamically
    # build an XPATH query. 
    my %definedouterfields;
    foreach my $name(keys %outerfields)
    {
        $definedouterfields{$name} = $outerfields{$name} if defined $$params{$name};
    }
    # Find out whether the machine name, compiler or test category are defined in the 
    # parameters, stash them here.  Now we can build our 'inner' XPATH query. 
    my %definedinnerfields;
    foreach my $name(keys %innerfields)
    {
        $definedinnerfields{$name} = $innerfields{$name} if defined $$params{$name};
    }

    # now construct the outer query. If the defined outer field has is set, we need to 
    # construct xpath queries appropriately. 
    
    # arrays for test nodes and machine nodes. 
    my @testnodes;
    my @machnodes;

    # if we found a test name, compset, grid, or testmods, 
    # construct an 'outer fields' query. 
    if(%definedouterfields)
    {
        #construct the attribute query. For every defined outer field,
        # add an attribute query, and 'and' if there are more than one. 
        $query .= "[";
        my @outerfields = keys %definedouterfields;
        while(@outerfields)
        {
            my $field = shift @outerfields;
            $query .= "\@$definedouterfields{$field}=\'$$params{$field}\'";
            $query .= " and "  if @outerfields;
        }
        $query .= "]";   

        # query the file looking for matching nodes. 
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $testxml = $parser->parse_file($filetoquery);
        @testnodes = $testxml->findnodes($query);
        foreach my $testnode(@testnodes)
        {
            # If we have defined inner fields, then construct the 
            # additional ./machines/machine attributes query with the 
            # defined inner fields.  
            if(%definedinnerfields)
            {
                my $iquery = "./machines/machine[";
                my @innerfields = keys %definedinnerfields;
                while(@innerfields)
                {
                    my $field = shift @innerfields;
                    $iquery .= "\@$definedinnerfields{$field}=\'$$params{$field}\'";
                    $iquery .= " and " if @innerfields;
                }
                $iquery .= "]";
                @machnodes = $testnode->findnodes($iquery);
            }
            # Otherwise, get all the machine children for this test node. 
            else
            {
                @machnodes = $testnode->findnodes('./machines/machine');
            }
        }
    }
    # if we only have machine name and/or compiler and/or category, do the same 
    # thing we do above, but for only the defined inner fields. 
    elsif(!%definedouterfields && %definedinnerfields)
    {
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $testxml = $parser->parse_file($filetoquery);
        @testnodes = $testxml->findnodes($query);
        foreach my $testnode(@testnodes)
        {
            
            my $iquery = "//machine[";
            my @innerfields = keys %definedinnerfields;
            while(@innerfields)
            {
                my $field = shift @innerfields;
                $iquery .= "\@$definedinnerfields{$field}=\'$$params{$field}\'";
                $iquery .= " and " if @innerfields;
            }
            $iquery .= "]";
            @machnodes = $testnode->findnodes($iquery);
        }
    }     
    # No query parameters passed, find EVERYTHING.. 
    else  
    {     
         my $parser = XML::LibXML->new(no_blanks => 1);
         my $testxml = $parser->parse_file($filetoquery);
         # this query finds ALL the tests. 
         @testnodes = $testxml->findnodes("//test");
    }
  
    foreach my $machnode(@machnodes)
       {
           # construct the cimetest at this level, we can get the
           # test node from the machine node, using the parent of the parent
           #
           my $cimetest = Testing::CIMETest->new();
           my $grandparent = $machnode->parentNode->parentNode;
           $cimetest->{testname} = $grandparent->getAttribute('name');
           $cimetest->{compset} = $grandparent->getAttribute('compset');
           $cimetest->{grid} = $grandparent->getAttribute('grid');
           my $mods = $grandparent->getAttribute('testmods');
           $cimetest->{testmods} = $mods if(defined $mods);
           $cimetest->{machine} = $machnode->getAttribute('name');
           $cimetest->{compiler} = $machnode->getAttribute('compiler');
           $cimetest->{category} = $machnode->getAttribute('category');
           push(@cimetestlist, $cimetest);
       }

    return @cimetestlist;
}



sub commify
{
	(@_ == 0) ? ''                :
	(@_ == 1) ? $_[0]             : 
	(@_ == 2) ?  join(" and ", @_) : 
				join(", ", @_[0 .. ($#_-1)], "and $_[-1]");
}

sub main
{
	my %case;
	$case{'compset'} = 'BC5';
	$case{'grid'} = 'ne30_g16';
	my $msg = Testing::TestLists->findTestsForCase(\%case);
}
main(@ARGV) unless caller();
1;
