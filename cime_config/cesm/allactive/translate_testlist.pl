#!/usr/bin/env perl 
#
use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
{
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
    sub repr()
    {
        my $self = shift;   
        my $rep = $self->{testname} . ".";
        $rep .= $self->{grid} . ".";
        $rep .= $self->{compset} . ".";
        $rep .= $self->{machine} . "_";
        $rep .= $self->{compiler} ;
        $rep .=  "." . $self->{testmods} if defined $self->{testmods};
        return $rep;
    }
}

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
                    push(@tests, $tst);
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
    
    while(@sortedtests)
    {
        my $test = shift @sortedtests;
        print $test->repr() , "\n";

    }
}
my $tests = &read_testlist( "./testlist_allactive.xml" );
&translate_testlist($tests);
