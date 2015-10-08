#!/usr/bin/env perl 
#
use strict;
use warnings;
use diagnostics;
use XML::LibXML;
use Data::Dumper;
{
    # Just a data class to make it easier to 
    # parse the xml testlist. 
    package CIMETest;
    sub new
    {
        my ($class,%params) = @_;
        my $self = {
            compset => $params{'compset'} || undef,
            grid => $params{'grid'} || undef,
            testname => $params{'testname'} || undef,
            machine => $params{'machine'} || undef,
            compiler => $params{'compiler'} || undef,
            model => $params{'model'} || undef,
            testmods => $params{'testmods'} || undef,
            comment => $params{'comment'} || undef,
            testtype => $params{'testtype'} || undef,
        };
    
        bless $self, $class;
        return $self;
    }
    
    # print the old-school test list format. 
    # 
    sub repr()
    {
        my $self = shift;   
        my $rep = $self->{testname} . ".";
        $rep .= $self->{grid} . ".";
        $rep .= $self->{compset} . ".";
        $rep .= $self->{machine} . "_";
        $rep .= $self->{compiler} . ".";
        $rep .= $self->{testtype} ;
        $rep .=  "." . $self->{testmods} if defined $self->{testmods};
        return $rep;
    }
}

# parse the testlist, return a list of CESMTest objects. 
sub read_testlist()
{
    my $xmlfile = shift;
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $testxml = $parser->parse_file($xmlfile);
    my @tests;
    
    foreach my $compsetnode($testxml->findnodes('./testlist/compset')) {
        foreach my $gridnode($compsetnode->findnodes('./grid')) {
            foreach my $testnode($gridnode->findnodes('./test')) {
                foreach my $machnode($testnode->findnodes('./machine')) {
                    my $compset = $compsetnode->getAttribute('name');
                    my $grid = $gridnode->getAttribute('name');
                    my $testname = $testnode->getAttribute('name');
                    my $machine = $machnode->textContent;
                    my $compiler = $machnode->getAttribute('compiler');
                    my $testtype = $machnode->getAttribute('testtype');
                    my $testmods = $machnode->getAttribute('testmods');
                    my $comment = $machnode->getAttribute('comment');

                    my $tst = new CIMETest(compset => $compset,
                                        grid => $grid,
                                        testname => $testname,
                                        machine => $machine,
                                        compiler => $compiler,
                                        testtype => $testtype);
                    if(defined $testmods) { $tst->{testmods} = $testmods; }
                    if(defined $comment) { $tst->{comment} = $comment; }
    
                    # compare the string representations to avoid 
                    # duplication. 
                    my $dupefound = 0;
                    foreach my $t(@tests)
                    {
                        if($t->repr() eq $tst->repr())
                        {
                            $dupefound = 1;
                            last;
                        }
                    }
                    push(@tests, $tst) if !$dupefound;
                }
            }
        }
    }
    foreach my $t(@tests)
    {
        print $t->repr() . "\n";
    }
    return \@tests;
    
}

sub translate_testlist()
{
    my $tests = shift;
    my $dom =  XML::LibXML::Document->createDocument();
    
    my $testlistelement = $dom->createElement('testlist');
    $dom->setDocumentElement($testlistelement);
    
    my @sortedtests = sort {
        $a->{testname} cmp $b->{testname}
    } @$tests;
    
    foreach my $test(@sortedtests)
    {
        #my $testelement = $testlistelement->createElement('test');
        my $name = $test->{testname};
        my $grid = $test->{grid};
        my $compset = $test->{compset};
        my $machine = $test->{machine};
        my $category = $test->{category};
        my $testmods = undef;
        $testmods = $test->{testmods} if defined $test->{testmods};
        my @existingnodes; 
        if(defined $testmods)
        {
            @existingnodes = 
            $testlistelement->findnodes("//test[\@name=\'$name\' and \@grid=\'$grid\' and \@compset=\'$compset\' and \@testmods=\'$testmods\']");
        }
        else
        {
            @existingnodes = $testlistelement->findnodes("//test[\@name=\'$name\' and \@grid=\'$grid\' and \@compset=\'$compset\']");
        }
        next if @existingnodes;
        
        my $testelement = XML::LibXML::Element->new('test');
        $testelement->setAttribute('name', $test->{testname});
        $testelement->setAttribute('grid', $test->{grid});
        $testelement->setAttribute('compset', $test->{compset});
        if(defined $test->{testmods})
        {
            $testelement->setAttribute('testmods', $test->{testmods});
        }
        my $machineselement = XML::LibXML::Element->new('machines');
        my $machineelement = XML::LibXML::Element->new('machine');
        $machineelement->setAttribute('name', $test->{machine});
        $machineelement->setAttribute('compiler', $test->{compiler});
        $machineelement->setAttribute('category', $test->{testtype});
        $machineselement->appendChild($machineelement);
        $testelement->appendChild($machineselement);
        $testlistelement->appendChild($testelement);
    
    }
    
    my $x = $dom->toString(1);
    print $x . "\n";
    
    #my @sortedtestscopy = @sortedtests;
    #while(@sortedtestscopy)
    my @testnodes = $testlistelement->findnodes("/testlist/test");
    foreach my $testelement(@testnodes)
    {
        #my $test = shift @sortedtestscopy;
        #foreach my $testelement(@testnodes)
        my @sortedtestscopy = @sortedtests;
        while(@sortedtestscopy)
        {
            my $test = shift @sortedtestscopy;
            #print "testnode name: ", $testnode->getAttribute('name'), "\n";
            #my @existingmachinesnode = $testelement->findnodes("//test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines");

            #my @existingtestnode;
            #if(defined $test->{testmods})
            #{
            #    @existingtestnode = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\' and \@testmods=\'$test->{testmods}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
            #}
            #else
            #{
            #    @existingtestnode  = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
            #}
            #if(! @existingmachinesnode && ! @existingtestnode )
            #{
            #    my $machineselement = XML::LibXML::Element->new('machines');
            #    my $machineelement = XML::LibXML::Element->new('machine');
            #    $machineelement->setAttribute('name', $test->{machine});
            #    #$machineelement->setAttribute('mpilib', '!mpi-serial');
            #    $machineelement->setAttribute('category', $test->{testtype});
            #    $machineelement->setAttribute('compiler', $test->{compiler});
            #    $machineselement->appendChild($machineelement);
            #    $testelement->appendChild($machineselement);
            #    next; 
            #}
            #else
            #{
            #    # We should at least have an existing 'machines' element, with one or more children.  
            #    # We should check to see if we have a match for the entirety of the test
            #    my @existingnodes; 
            #    if(defined $test->{testmods})
            #    {
            #        #print "testmods defined\n";
            #        @existingnodes = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\' and \@testmods=\'$test->{testmods}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
            #    }
            #    else
            #    {
            #        #print "testmods NOT defined\n";
            #        @existingnodes = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
            #    }
            #    # If we don't have a test match, we need to add the new machine element to the machines element, 
            #    # add that to the machines element
            #    if(! @existingnodes)
            #    {
            #        my @machinesnodes = $testelement->findnodes("//test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines");
            #        my $machinesnode = $machinesnodes[0];
            #        my $newmachinenode = XML::LibXML::Element->new('machine');
            #        $newmachinenode->setAttribute('name', $test->{machine});
            #        $newmachinenode->setAttribute('category', $test->{testtype});
            #        $newmachinenode->setAttribute('compiler', $test->{compiler});
            #        
            #        $machinesnode->appendChild($newmachinenode);
            #    }
            #}
        }
    }
    $x = $dom->toString(1);
    print $x . "\n";
    return $dom;
}
my $tests = &read_testlist( "./testlist_allactive.xml" );
my $newdom = &translate_testlist($tests);
