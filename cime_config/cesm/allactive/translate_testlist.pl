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
            if(! $testelement->hasChildNodes())
            {
                my $machineselement = XML::LibXML::Element->new('machines');
                my $machineelement = XML::LibXML::Element->new('machine');
                $machineelement->setAttribute('name', $test->{machine});
                #$machineelement->setAttribute('mpilib', '!mpi-serial');
                $machineelement->setAttribute('category', $test->{testtype});
                $machineelement->setAttribute('compiler', $test->{compiler});
                $machineselement->appendChild($machineelement);
                $testelement->appendChild($machineselement);
                next; 
            }
            else
            {
                my @existingnodes; 
                if(defined $test->{testmods})
                {
                    print "testmods defined\n";
                    @existingnodes = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\' and \@testmods=\'$test->{testmods}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\']");
                }
                else
                {
                    print "testmods NOT defined\n";
                    @existingnodes = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\']");
                }
                print Dumper \@existingnodes;
                if(@existingnodes)
                {
                    my @machinesnodes = $dom->findnodes("/testlist/test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines");
                    my $machinesnode = $machinesnodes[0];
    
                    my $machineelement = XML::LibXML::Element->new('machine');
                    $machineelement->setAttribute('name', $test->{machine});
                    $machineelement->setAttribute('category', $test->{testtype});
                    $machineelement->setAttribute('compiler', $test->{compiler});
                    $machinesnode->appendChild($machineelement);
                }
            
            }
        }
    }
    $x = $dom->toString(1);
    print $x . "\n";
}
my $tests = &read_testlist( "./testlist_allactive.xml" );
&translate_testlist($tests);
