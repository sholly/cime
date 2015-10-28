#!/usr/bin/env perl 
#
use strict;
use warnings;
use diagnostics;
use XML::LibXML;
use Data::Dumper;
use File::Basename;
use POSIX qw(strftime);
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
    
    # print the textual format for comparison purposes
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
    print "reading $xmlfile\n";
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
    #foreach my $t(@tests)
    #{
    #    print $t->repr() . "\n";
    #}
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
        # Spoke with alice, perhaps an options element??
        my $optionselement = XML::LibXML::Element->new('options');
        my $wallclock = XML::LibXML::Element->new('option');
        $wallclock->setAttribute('name', 'wallclock');
        $wallclock->appendText("2:00");
        $optionselement->appendChild($wallclock);
        my $pecount = XML::LibXML::Element->new('option');
        $pecount->setAttribute('name', 'pecount');
        $pecount->appendText("L");
        $optionselement->appendChild($pecount);
        $machineelement->appendChild($optionselement);
        $machineselement->appendChild($machineelement);
        $testelement->appendChild($machineselement);
        $testlistelement->appendChild($testelement);
    
    }
    
    
    my @sortedtestscopy = @sortedtests;
    while(@sortedtestscopy)
    {
        my $test = shift @sortedtestscopy;
        #print "test: ", $test->repr(), "\n";
        #print Dumper $test;
        my @existingtestnode;
        if(defined $test->{testmods})
        {
            @existingtestnode = $dom->findnodes("//test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\' and \@testmods=\'$test->{testmods}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
        }
        else
        {
            @existingtestnode  = $dom->findnodes("//test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines/machine[\@name=\'$test->{machine}\' and \@compiler=\'$test->{compiler}\' and \@category=\'$test->{testtype}\']");
        }
        #print Dumper \@existingtestnode;
        if(! @existingtestnode)
        {
            # find the <machines> element for this test node.
            my @existingmachinesnodes = $dom->findnodes("//test[\@name=\'$test->{testname}\' and \@grid=\'$test->{grid}\' and \@compset=\'$test->{compset}\']/machines");
            #print Dumper \@existingmachinesnodes;
           
            my $existingmachinesnode = $existingmachinesnodes[0];
            my $machineelement = XML::LibXML::Element->new('machine');

            my $optionselement = XML::LibXML::Element->new('options');
            my $wallclock = XML::LibXML::Element->new('option');
            $wallclock->setAttribute('name', 'wallclock');
            $wallclock->appendText("4:00");
            $optionselement->appendChild($wallclock);
            my $pecount = XML::LibXML::Element->new('option');
            $pecount->setAttribute('name', 'pecount');
            $pecount->appendText("L");
            $optionselement->appendChild($pecount);
            $machineelement->appendChild($optionselement);

            $machineelement->setAttribute('name', $test->{machine});
            $machineelement->setAttribute('compiler', $test->{compiler});
            $machineelement->setAttribute('category', $test->{testtype});

            $existingmachinesnode->appendChild($machineelement);
            next;
        }
    }
    return $dom;
}

sub writeXML
{
    my $newdom = shift;
    my $oldfilepath = shift;
    my ($oldname, $oldpath, $oldsuffix) = fileparse($oldfilepath);
    my $dtformat = strftime "%d%b%Y-%H%M%S",  localtime;
    my $newname = $oldname;
    $newname =~ s/\.xml//g;
    #$newname .= "$dtformat.xml";
    $newname .= "new.xml";
    my $newfile = $oldpath . $newname;
    print "writing $newfile\n";
    #my $newfile = "./testlist_allactive.$dtformat.xml";
    open my $NEWXML, ">", "$newfile" or die $?;
    my $newstring = $newdom->toString(1);
    print $NEWXML $newstring;
    close $NEWXML;
}
sub main()
{
    my @origfilepaths = (
                           "../cime_config/cesm/allactive/testlist_allactive.xml",
                           "../../components/rtm/cime_config/testdefs/testlist_rtm.xml",
                           "../../components/clm/cime_config/testdefs/testlist_clm.xml",
                           "../../components/cice/cime_config/testdefs/testlist_cice.xml",
                           "../../components/pop/cime_config/testdefs/testlist_pop.xml",
                           "../../components/cism/cime_config/testdefs/testlist_cism.xml",
                           "../../components/cam/cime_config/testdefs/testlist_cam.xml",
                        );
    foreach my $oldfile(@origfilepaths)
    {
        my $tests = &read_testlist($oldfile);
        my $newdom = &translate_testlist($tests);
        &writeXML($newdom, $oldfile);
    }
}

main();
