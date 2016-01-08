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
# find a set of tests given appropriate XPath query options. 
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
    my $component = $$params{'component'} if defined $$params{'component'};
    my $compset = $$params{'compset'} if defined $$params{'compset'};
    my $grid = $$params{'grid'} if defined $$params{'grid'};
    my $machine = $$params{'machine'} if defined $$params{'machine'};
    my $compiler = $$params{'compiler'} if defined $$params{'compiler'};
    my $testmods = $$params{'testmods'} if defined $$params{'testmods'};
    my $testname = $$params{'testname'} if defined $$params{'testname'};
    my $category = $$params{'category'} if defined $$params{'category'};
    
    
    my @cimetestlist;
    #my $query = "//test[";
    my $query = "/testlist/test";
    # If any of the 'outer' attributes are defined: name of the test, grid, 
    # compset or testmods, add attribute search query options to the query. 
    my %outerfields = ( testname => 'name', grid => 'grid', compset => 'compset', 
                        testmods => 'testmods');
    my %innerfields = ( machine => 'name', compiler => 'compiler', category => 'category');

    # Create two hashes of the testlist xml attributes that are actually defined in the 
    # parameters for this file. 
    #
    my %definedouterfields;
    foreach my $name(keys %outerfields)
    {
        $definedouterfields{$name} = $outerfields{$name} if defined $$params{$name};
    }
    print Dumper \%definedouterfields;
    my %definedinnerfields;
    foreach my $name(keys %innerfields)
    {
        $definedinnerfields{$name} = $innerfields{$name} if defined $$params{$name};
    }
    print Dumper \%definedinnerfields;

    # now construct the outer query. If the defined outer field has is set, we need to 
    # construct xpath queries appropriately. 
    my @testnodes;
    my @machnodes;
    if(%definedouterfields)
    {
        $query .= "[";
        my @outerfields = keys %definedouterfields;
        while(@outerfields)
        {
            my $field = shift @outerfields;
            $query .= "\@$definedouterfields{$field}=\'$$params{$field}\'";
            $query .= " and "  if @outerfields;
        }
        $query .= "]";   

        print $query;
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $testxml = $parser->parse_file($filetoquery);
        @testnodes = $testxml->findnodes($query);
        foreach my $testnode(@testnodes)
        {
            if(%definedinnerfields)
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
            else
            {
                @machnodes = $testnode->childNodes();
            }
            foreach my $machnode(@machnodes)
            {
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
                print Dumper $cimetest;
                push(@cimetestlist, $cimetest);
            }
        }
    }
    else
    {
        #my $parser = XML::LibXML->new(no_blanks => 1);
        #my $testxml = $parser->parse_file($filetoquery);
        #@testnodes = $testxml->findnodes("//test");
        #foreach my $testnode(@testnodes)
        #{
        #    @machnodes = $testnode->childNodes();
        #    foreach my $machnode(@machnodes)
        #    {
        #        my $cimetest = Testing::CIMETest->new();
        #        my $grandparent = $machnode->parentNode->parentNode;
        #        $cimetest->{testname} = $grandparent->getAttribute('name');
        #        $cimetest->{compset} = $grandparent->getAttribute('compset');
        #        $cimetest->{grid} = $grandparent->getAttribute('grid');
        #        my $mods = $grandparent->getAttribute('testmods');
        #        $cimetest->{testmods} = $mods if(defined $mods);
        #        $cimetest->{machine} = $machnode->getAttribute('name');
        #        $cimetest->{compiler} = $machnode->getAttribute('compiler');
        #        $cimetest->{category} = $machnode->getAttribute('category');
        #        print Dumper $cimetest;
        #        push(@cimetestlist, $cimetest);
        #    }
        #}

    }

    #if(%definedinnerfields)
    #{
    #    #$query .= "/machines/";
    #    $query .= "[./machines/machine/";

    #    my @innerfields = keys %definedinnerfields;
    #    while(@innerfields)
    #    {
    #        my $field = shift @innerfields;
    #        $query .= "\@$definedinnerfields{$field}=\'$$params{$field}\'";
    #        $query .= " and " if @innerfields;
    #    }
    #    $query .= "]";
    #}
    
    
    
                      
    
    # Iterate through each component we want to query. 
    #foreach my $comp(@filestoquery)
    #{
    #    # Dynamically set up the XPath query based on whether testname, compset, 
    #    # grid, and/or testmods is defined.  
    #    my $outerquery = "//test";
    #    # set up the outer fields name->value hash to construct fields we need to search for 
    #    # via XPath
    #    my %outerfields = ( name => 'testname', grid => 'grid', compset => 'compset', 
    #                        testmods => 'testmods');
    #    my $outernamesdefined = 0;
    #    if(defined $testname || defined $grid || defined $compset || defined $testmods)
    #    {
    #        $outernamesdefined = 1;
    #        $outerquery .= "[";
    #    
    #        my @outerfieldnames = keys %outerfields;
    #        while(@outerfieldnames)
    #        {
    #            my $field = shift @outerfieldnames;
    #            $outerquery .= "\\@$field=\'$outerfields{$field}\'" ;
    #            $outerquery .= " and " if @outerfieldnames;
    #        }
    #    }
    #    $outerquery .= "]" if $outernamesdefined;
    #    
    #    print "outerquery: $outerquery\n";
    #    my $parser = XML::LibXML->new( no_blanks => 1);
    #    my $xml = $parser->parse_file($comp);
    #    my @testnodes = $xml->findnodes($outerquery);
    #    print Dumper \@testnodes;
    #    foreach my $testnode(@testnodes)
    #    {
    #        my $innerquery = "//machines";

    #        my %innerfields = ( name => 'machine', compiler => 'compiler', category => 'category');
    #        my $innernamesdefined = 0;
    #        if(defined $machine || defined $compiler || defined $category)
    #        {
    #            $innernamesdefined = 1;
    #            $innerquery .= "[";
    #        
    #            my @innerfieldnames = keys %innerfields;
    #            while(@innerfieldnames)
    #            {
    #                my $field = shift @innerfieldnames;
    #                $innerquery .= "\\\@$field=\'$innerfields{$field}\'";
    #                $innerquery .= " and " if @innerfieldnames;
    #                print "innerquery ", $innerquery, "\n";
    #            }
    #        }
    #        $innerquery .= "]" if $innernamesdefined;      
    #        print "query: $innerquery\n";
    #        my @machinenodes = $testnode->findnodes($innerquery);
    #        foreach my $machinenode(@machinenodes)
    #        {
    #            my $xcompset = $testnode->getAttribute('name');
    #            my $xgrid = $testnode->getAttribute('grid');
    #            my $xtestmods = undef;
    #            
    #            if($testnode->hasAttribute('testmods'))
    #            {
    #                $xtestmods =$testnode->getAttribute('testmods');
    #            }

    #            my $xmachine = $machinenode->getAttribute('name');
    #            my $xcompiler = $machinenode->getAttribute('compiler');
    #            my $xcategory = $machinenode->getAttribute('category');
    #
    #            my $cimetest = new CIMETest(compset => $xcompset, grid => $xgrid,
    #                                        machine => $xmachine, compiler => $xcompiler,
    #                                        category => $xcategory);
    #            $cimetest->setTestMods($xtestmods) if defined $xtestmods;
    #
    #            my @optionnodes = $machinenode->findnodes("//options/option");
    #            foreach my $optionnode(@optionnodes)
    #            {
    #                my $name = $optionnode->getAttribute('name');
    #                my $value = $optionnode->textContent;
    #                $cimetest->setOption($name, $value);
    #            }
    #
    #            push($cimetest, @cimetestlist);
    #        }

    #    }
    #}
    return @cimetestlist;
    #
    ##my $query = "//test";
    ###my %outerfields = qw/ name grid compset testmods/;
    ##my %outerfields = { name => 'testname', grid => 'grid', compset => 'compset'
    ##                    testmods => 'testmods'};
    ##my $outernamesdefined = 0;
    ##if(defined $testname || defined $grid || defined $compset || defined $testmods)
    #{
    #    $outernamesdefined = 1;
    #    $query .= "[";
    #}
    #my @outerfieldnames = keys %outerfields;
    #while(@outerfieldnames)
    #{
    #    my $field = shift @outerfieldnames;
    #    $query .= "\@$field=\'$outerfields{$field}\'" ;
    #    $query .= " and " if @outerfieldnames;
    #}
    #$query .= "]" if $outernamesdefined;
    #$query .= "/machines/machine";
    #
    #my %innerfields = { name => 'machine', compiler => 'compiler', category => 'category'};
    #my $innernamesdefined = 0;
    #if(defined $machine || defined $compiler || defined $category)
    #{
    #    $innernamesdefined = 1;
    #    $query .= "[";    
    #}
    #my @innerfieldnames = keys %innerfields;
    #while(@innerfieldnames)
    #{
    #    my $field = shift @innerfieldnames;
    #    $query .= "\@$field=\'$innerfields{$field}\'";
    #    $query .= " and " if @innerfieldnames;
    #}
    #$query .= "]" if $innernamesdefined;
    #    
    #   
    #    
    #}

}

#sub findTestsForCase()
#	my $self = shift;
#	my ($args) = @_;
#	my $compset = $$args{'compset'} if defined $$args{'compset'};
#	my $grid = $$args{'grid'} if defined $$args{'compset'};
#	my $machine = $$args{'machine'} if defined $$args{'machine'};
#	my $compiler = $$args{'compiler'} if defined $$args{'compiler'};
#	my $cesmtest = new CESMTest(compset => $compset, grid => $grid, 
#							    machine => $machine, compiler => $compiler);
#
#	my $testxml = $self->_readTestListXML();
#
#	my $root = $testxml->getDocumentElement();
#	my @machinesforcase;
#	my @compilersforcase;
#	my @testsforcase;
#
#	# find the matching compset..
#	foreach my $compsetnode($root->findnodes('/testlist/compset'))
#	{
#		my $compsetname = $compsetnode->getAttribute('name');
#		# skip unless the compset names match
#		if(defined $cesmtest->{compset})
#		{
#			next unless $cesmtest->{compset} eq $compsetname;
#		}
#	
#		my @gridnodes = $compsetnode->findnodes('./grid');
#		foreach my $gridnode($compsetnode->findnodes('./grid'))
#		{
#			my $gridname = $gridnode->getAttribute('name');
#
#			# skip unless the grid names match
#			if(defined $cesmtest->{grid})
#			{
#				next unless $cesmtest->{grid} eq $gridname;
#			}
#			
#			foreach my $testnode($gridnode->findnodes('./test'))
#			{
#				my $testname = $testnode->getAttribute('name');
#				my @machnodes = $testnode->findnodes('./machine');
#				foreach my $machnode(@machnodes)
#				{
#					push(@machinesforcase, $machnode->textContent());
#					push(@compilersforcase, $machnode->getAttribute('compiler'));
#					push(@testsforcase, $machnode->getAttribute('testtype'));
#				}
#			}
#		}
#	}
#
#	# Now, make sure the machine, compiler names are unique..
#	my @compilers;
#	my @machines;
#	my @testtypes;
#	my %uniqcompilers;
#	my %uniqmachines;
#	my %uniqtesttypes;
#
#	map { $uniqcompilers{$_} = 1 } @compilersforcase;
#	@compilers = sort keys %uniqcompilers;
#	map { $uniqmachines{$_} = 1 } @machinesforcase;
#	@machines = sort keys %uniqmachines;
#	map { $uniqtesttypes{$_} = 1 } @testsforcase;
#	@testtypes = sort keys %uniqtesttypes;
#	
#	if (! @compilers && ! @machines && ! @testtypes)
#	{
#		my $msg = <<END;
#WARNING:: The following compset/grid combination $cesmtest->{compset}/$cesmtest->{grid} is NOT 
#tested during the standard CESM development process. Thus you may likely find that this configuration
#will NOT work, and are on your own to figure out how to get it working.
#END
#		return $msg;
#	}
#		
#my $msg = <<END;
#The compset $cesmtest->{compset} and grid $cesmtest->{grid} are tested on the following
#machines, compilers, and/or test categories: 
#END
#	my $line = '';
#	if(@machines)
#	{
#		$msg .= "Machines: ";
#		$line = commify(@machines);
#
#    	$msg .= "$line\n";
#	}
#	
#	if(@compilers)
#	{
#		$msg .= "Compilers: ";
#		$line = commify(@compilers);
#    	$msg .= "$line\n";
#	}
#	
#	if(@testtypes)
#	{
#		$msg .= "Test Types: ";
#		$line = commify(@testtypes);
#    	$msg .= "$line\n";
#	}
#$msg .= <<END;
#The closer the tests are to the machine and compiler you are using and the more tests
#that are done, the more likely your case will work without trouble.
#END
#	
#	return $msg;
#	
#}

sub _readTestListXML
{
	my $self = shift;
	my $parser = XML::LibXML->new( no_blanks => 1);
	my $testxml = $parser->parse_file($self->{'testlistxml'});
	return $testxml;

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
