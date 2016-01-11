#==========================================================================
# Simple attribute class to facilitate easier test parsing..
#==========================================================================
package Testing::CIMETest;

sub new
{
    my ($class, %params) = @_;

    my $self = {
        compset => $params{'compset'} || undef,
        grid    => $params{'grid'} || undef,
        testname => $params{'testname'} || undef,
        machine  => $params{'machine'} || undef,
        compiler  => $params{'compiler'} || undef,
        testmods  => $params{'testmods'} || undef,
        comment  => $params{'comment'} || undef,
    };
    bless $self, $class;
    return $self;
}

sub setTestMods()
{
    my $self = shift;
    my $testmods = shift;
    $self->{testmods} = $testmods;
}

sub addOption()
{
    my $self = shift;
    my $name = shift;
    my $value = shift;
    $self->{options}->{$name} = $value;
}

sub getOption()
{
    my $self = shift;
    my $name = shift;
    if(defined $self->{options}->{$name})
    {
        return $self->{options}->{$name}
    }
    else
    {
        return undef;
    }
}
1;