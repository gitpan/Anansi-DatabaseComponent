package Anansi::DatabaseComponent;


=head1 NAME

Anansi::DatabaseComponent - A manager template for database drivers.

=head1 SYNOPSIS

    package Anansi::Database::Example;

    use base qw(Anansi::DatabaseComponent);

    sub connect {
        my ($self, $channel, %parameters) = @_;
        return $self->SUPER::connect(
            undef,
            INPUT => [
                'some text',
                {
                    NAME => 'someParameter'
                }, {
                    INPUT => [
                        'more text',
                        {
                            NAME => 'anotherParameter'
                        },
                        'yet more text'
                    ]
                }, {
                    DEFAULT => 'abc',
                    NAME => 'yetAnotherParameter'
                }
            ],
            someParameter => 12345,
            anotherParameter => 'blah blah blah'
        );
    }

    sub validate {
        my ($self, $channel, %parameters) = @_;
        return Anansi::DatabaseComponent::validate(undef, DRIVER => 'Example');
    }

    Anansi::Component::addChannel('Anansi::Database::Example', 'AUTOCOMMIT' => 'Anansi::DatabaseComponent::autocommit');
    Anansi::Component::addChannel('Anansi::Database::Example', 'COMMIT' => 'Anansi::DatabaseComponent::commit');
    Anansi::Component::addChannel('Anansi::Database::Example', 'CONNECT' => 'connect');
    Anansi::Component::addChannel('Anansi::Database::Example', 'DISCONNECT' => 'Anansi::DatabaseComponent::disconnect');
    Anansi::Component::addChannel('Anansi::Database::Example', 'FINISH' => 'Anansi::DatabaseComponent::finish');
    Anansi::Component::addChannel('Anansi::Database::Example', 'HANDLE' => 'Anansi::DatabaseComponent::handle');
    Anansi::Component::addChannel('Anansi::Database::Example', 'PREPARE' => 'Anansi::DatabaseComponent::prepare');
    Anansi::Component::addChannel('Anansi::Database::Example', 'ROLLBACK' => 'Anansi::DatabaseComponent::rollback');
    Anansi::Component::addChannel('Anansi::Database::Example', 'STATEMENT' => 'Anansi::DatabaseComponent::statement');
    Anansi::Component::addChannel('Anansi::Database::Example', 'VALIDATE_AS_APPROPRIATE' => 'validate'); 

    1;

=head1 DESCRIPTION

Manages a database connection providing generic processes to allow it's opening,
closing and various SQL interactions.  Uses L<Anansi::Actor>,
L<Anansi::Component> and L<base>.

=cut


our $VERSION = '0.03';

use base qw(Anansi::Component);

use Anansi::Actor;


=head1 INHERITED METHODS

=cut


=head2 addChannel

Declared in L<Anansi::Component>.

=cut


=head2 channel

Declared in L<Anansi::Component>.

=cut


=head2 componentManagers

Declared in L<Anansi::Component>.

=cut


=head2 finalise

    $OBJECT->SUPER::finalise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    $self->finish();
    $self->disconnect();
}


=head2 implicate

Declared in L<Anansi::Class>.  Intended to be overridden by an extending module.

=cut


=head2 import

Declared in L<Anansi::Class>.

=cut


=head2 initialise

    $OBJECT->SUPER::initialise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    Anansi::Actor->new(
        PACKAGE => 'DBI',
    );
    $self->{STATEMENT} = {};
}


=head2 old

Declared in L<Anansi::Class>.

=cut


=head2 removeChannel

Declared in L<Anansi::Component>.

=cut


=head2 used

Declared in L<Anansi::Class>.

=cut


=head2 uses

Declared in L<Anansi::Class>.

=cut


=head1 METHODS

=cut


=head2 autoCommit

    if(1 == Anansi::DatabaseComponent::autocommit($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'AUTOCOMMIT'));

    if(1 == $OBJECT->autocommit(undef));

    if(1 == $OBJECT->channel('AUTOCOMMIT'));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database autocommit.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.

=cut


sub autocommit {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my $autocommit;
    eval {
        $autocommit = $self->{HANDLE}->autocommit();
        1;
    } or do {
        return 0;
    };
    return 0 if(!defined($autocommit));
    return 0 if(ref($autocommit) !~ /^$/);
    return 0 if($autocommit !~ /^[\+\-]?\d+$/);
    return 1 if($autocommit);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'AUTOCOMMIT' => 'autocommit');


=head2 bind

    if(Anansi::DatabaseComponent::bind($OBJECT,
        HANDLE => $HANDLE,
        INPUT => [
            {
                NAME => 'someParameter'
            }, {
                DEFAULT => 123,
                NAME => 'anotherParameter'
            }
        ],
        VALUE => {
            someParameter => 'abc'
        }
    ));

    if($OBJECT->bind(
        HANDLE => $HANDLE,
        INPUT => [
            {
                NAME => 'yetAnotherParameter',
                TYPE => 'TEXT'
            }
        ],
        VALUE => [
            yetAnotherParameter => 456
        ]
    ));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item HANDLE I<(DBI::st, Required)>

The database statement handle.

=item INPUT I<(Array, Required)>

An array of hashes.  Each element of the array corresponds to an equivalent B<?>
I<(Question mark)> within the prepared SQL statement.  Each hash contains a
I<NAME> key with a value that represents a possible key within the I<VALUE>
parameter.  Each hash may also contain a I<DEFAULT> key which contains the value
to use if the equivalent I<VALUE> parameter does not exist and a I<TYPE> key
which contains the SQL type to associate with the assigned value.  When no
corresponding I<VALUE> parameter key exists and no I<DEFAULT> key has been
defined then an empty string is used for the value.

=item VALUE I<(Hash, Required)>

A hash of values to assign in the order specified by the I<INPUT> parameter.

=back

=back

Attempts to use the supplied parameters to assign values to a SQL statement that
has already been prepared to accept them.  Returns B<0> I<(zero)> on failure and
the database statement handle on success.

=cut


sub bind {
    my ($self, %parameters) = @_;
    return 0 if(!defined($parameters{HANDLE}));
    return 0 if(!defined($parameters{INPUT}));
    return 0 if(ref($parameters{INPUT}) !~ /^ARRAY$/i);
    return 0 if(!defined($parameters{VALUE}));
    return 0 if(ref($parameters{VALUE}) !~ /^HASH$/i);
    my $index = 1;
    foreach my $input (@{$parameters{INPUT}}) {
        if(defined(${$parameters{VALUE}}{${$input}{NAME}})) {
            if(defined(${$input}{TYPE})) {
                $parameters{HANDLE}->bind_param($index, ${$parameters{VALUE}}{${$input}{NAME}}, ${$input}{TYPE});
            } else {
                $parameters{HANDLE}->bind_param($index, ${$parameters{VALUE}}{${$input}{NAME}});
            }
        } elsif(defined(${$input}{DEFAULT})) {
            if(defined(${$input}{TYPE})) {
                $parameters{HANDLE}->bind_param($index, ${$input}{DEFAULT}, ${$input}{TYPE});
            } else {
                $parameters{HANDLE}->bind_param($index, ${$input}{DEFAULT});
            }
        } elsif(defined(${$input}{TYPE})) {
            $parameters{HANDLE}->bind_param($index, '', ${$input}{TYPE});
        } else {
            $parameters{HANDLE}->bind_param($index, '');
        }
        $index++;
    }
    return $parameters{HANDLE};
}


=head2 binding

    if(1 == Anansi::DatabaseComponent::binding($OBJECT));

    if(1 == $OBJECT->binding());

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Array, Optional)>

An array of hashes.  Each hash should contain a I<NAME> key with a string value.

=back

Verifies that the supplied parameters are all hashes and that they each contain
a I<NAME> key with a string value.  Returns B<1> I<(one)> when validity is
confirmed and B<0> I<(zero)> when an invalid structure is determined.  Used to
validate the I<INPUT> parameter of the B<bind> method.

=cut


sub binding {
    my ($self, @parameters) = @_;
    foreach my $parameter (@parameters) {
        return 0 if(ref($parameter) !~ /^HASH$/i);
        return 0 if(!defined(${$parameter}{NAME}));
        return 0 if(ref(${$parameter}{NAME}) !~ /^$/);
        return 0 if(${$parameter}{NAME} !~ /^[a-zA-Z_]+(\s*[a-zA-Z0-9_]+)*$/);
    }
    return 1;
}


=head2 commit

    if(1 == Anansi::DatabaseComponent::commit($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'COMMIT'));

    if(1 == $OBJECT->commit(undef));

    if(1 == $OBJECT->channel('COMMIT'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database commit.  Returns B<1> I<(one)> on success and
B<0> I<(zero)> on failure.

=cut


sub commit {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if(!defined($self->{HANDLE}));
    return 1 if($self->autocommit());
    my $commit;
    eval {
        $commit = $self->{HANDLE}->commit();
        1;
    } or do {
        $self->rollback();
        return 0;
    };
    return 0 if(!defined($commit));
    return 0 if(ref($commit) !~ /^$/);
    return 0 if($commit !~ /^[\+\-]?\d+$/);
    return 1 if($commit);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'COMMIT' => 'commit');


=head2 connect

    if(1 == Anansi::DatabaseComponent::connect($OBJECT, undef
        INPUT => [
            'some text',
            {
                NAME => 'someParameter'
            }, {
                INPUT => [
                    'more text',
                    {
                        NAME => 'anotherParameter'
                    },
                    'yet more text'
                ]
            }, {
                DEFAULT => 'abc',
                NAME => 'yetAnotherParameter'
            }
        ],
        someParameter => 12345,
        anotherParameter => 'blah blah blah'
    ));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'CONNECT',
        INPUT => [
            'blah blah blah',
            {
                DEFAULT => 123,
                NAME => 'someParameter',
            }
        ],
        someParameter => 'some text'
    ));

    if(1 == $OBJECT->connect(undef,
        INPUT => [
            {
                INPUT => [
                    'some text',
                    {
                        NAME => 'someParameter'
                    },
                    'more text'
                ]
            }
        ],
        someParameter => 'in between'
    ));

    if(1 == $OBJECT->channel('CONNECT',
        INPUT => [
            {
                INPUT => [
                    {
                        NAME => 'abc'
                    }, {
                        NAME => 'def'
                    }
                },
                REF => 'HASH'
            }
        ]
    ));

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Required)>

Named parameters.

=over 4

=item INPUT I<(Array B<or> Scalar, Required)>

An array or single value containing a description of each parameter in the order
that it is passed to the database driver's I<connect> method.

=over 4

=item I<(Non-Hash)>

An element that does not contain a hash value will be used as the corresponding
I<connect> method's parameter value.

=item I<(Hash)>

An element that contains a hash value is assumed to be a description of how to
generate the corresponding I<connect> method's parameter value.  when a value
can not be generated, an B<undef> value will be used.

=over 4

=item DEFAULT I<(Optional)>

The value to use if no other value can be determined.

=item INPUT I<(Array B<or> Scalar, Optional)>

Contains a structure like that given in I<INPUT> above with the exception that
any further I<INPUT> keys will be ignored.  As this key is only valid when
I<NAME> is undefined and I<REF> either specifies a string or a hash, it's value
will be either a concatenation of all the calculated strings or a hash
containing all of the specified keys and values.

=item NAME I<(String, Optional)>

The name of the parameter that contains the value to use.

=item REF I<(Array B<or> String, Optional)>

The data types used to validate the value to use.

=back

=back

=back

=back

Attempts to perform a database connection using the supplied parameters.
Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.

=cut


sub connect {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    $self->disconnect();
    return 0 if(!defined($parameters{INPUT}));
    return 0 if(ref($parameters{INPUT}) !~ /^ARRAY$/i);
    my @inputs;
    foreach my $input (@{$parameters{INPUT}}) {
        if(ref($input) !~ /^HASH$/i) {
            push(@inputs, $input);
            next;
        }
        my $value = undef;
        $value = ${$input}{DEFAULT} if(defined(${$input}{DEFAULT}));
        if(!defined(${$input}{NAME})) {
            if(!defined(${$input}{INPUT})) {
            } elsif(ref(${$input}{INPUT}) !~ /^ARRAY$/i) {
            } elsif(!defined(${$input}{REF})) {
            } elsif(ref(${$input}{REF}) !~ /^$/i) {
            } elsif('' eq ${$input}{REF}) {
                my @subInputs;
                for(my $index = 0; $index < scalar(@{${$input}{INPUT}}); $index++) {
                    if(ref(${${$input}{INPUT}}[$index]) =~ /^$/i) {
                        push(@subInputs, ${${$input}{INPUT}}[$index]);
                        next;
                    } elsif(ref(${${$input}{INPUT}}[$index]) !~ /^HASH$/) {
                        next;
                    }
                    my $subValue = '';
                    $subValue = ${${${$input}{INPUT}}[$index]}{DEFAULT} if(defined(${${${$input}{INPUT}}[$index]}{DEFAULT}));
                    if(!defined(${${${$input}{INPUT}}[$index]}{NAME})) {
                    } elsif(ref(${${${$input}{INPUT}}[$index]}{NAME}) !~ /^$/) {
                    } elsif(defined($parameters{${${${$input}{INPUT}}[$index]}{NAME}})) {
                        if(!defined(${${${$input}{INPUT}}[$index]}{REF})) {
                            $subValue = $parameters{${${${$input}{INPUT}}[$index]}{NAME}} if('' eq ref($parameters{${${${$input}{INPUT}}[$index]}{NAME}}));
                        } elsif(ref(${${${$input}{INPUT}}[$index]}{REF}) !~ /^$/) {
                        } elsif('' ne ${${${$input}{INPUT}}[$index]}{REF}) {
                        } elsif('' ne ref($parameters{${${${$input}{INPUT}}[$index]}{NAME}})) {
                        } else {
                            $subValue = $parameters{${${${$input}{INPUT}}[$index]}{NAME}};
                        }
                    }
                    push(@subInputs, $subValue);
                }
                $value = join('', @subInputs);
            } elsif(${$input}{REF} =~ /^HASH$/i) {
                my %subInputs;
                foreach my $subInput (@{${$input}{INPUT}}) {
                    next if(ref($subInput) !~ /^HASH$/i);
                    my $subValue = undef;
                    $subValue = ${$subInput}{DEFAULT} if(defined(${$subInput}{DEFAULT}));
                    if(!defined(${$subInput}{NAME})) {
                    } elsif(ref(${$subInput}{NAME}) !~ /^$/) {
                    } elsif(defined($parameters{${$subInput}{NAME}})) {
                        if(!defined(${$subInput}{REF})) {
                        } elsif(ref(${$subInput}{REF}) =~ /^ARRAY$/i) {
                            my %refs = map { $_ => 1 } (@{${$subInput}{REF}});
                            $subValue = $parameters{${$subInput}{NAME}} if(defined($refs{ref($parameters{${$subInput}{NAME}})}));
                        } elsif(ref(${$subInput}{REF}) !~ /^$/) {
                        } elsif(${$subInput}{REF} ne ref($parameters{${$subInput}{NAME}})) {
                        } else {
                            $subValue = $parameters{${$subInput}{NAME}};
                        }
                    }
                    $subInputs{${$subInput}{NAME}} = $subValue;
                }
                $value = \%subInputs;
            }
        } elsif(ref(${$input}{NAME}) !~ /^$/) {
        } elsif(defined($parameters{${$input}{NAME}})) {
            if(!defined(${$input}{REF})) {
            } elsif(ref(${$input}{REF}) =~ /^ARRAY$/i) {
                my %refs = map { $_ => 1 } (@{${$input}{REF}});
                if(!defined($refs{ref($parameters{${$input}{NAME}})})) {
                } elsif(ref($parameters{${$input}{NAME}}) !~ /^HASH$/i) {
                    $value = $parameters{${$input}{NAME}};
                } else {
                    if(!defined(${$input}{INPUT})) {
                        $value = $parameters{${$input}{NAME}};
                    } elsif(ref(${$input}{INPUT}) !~ /^HASH$/i) {
                        $value = $parameters{${$input}{NAME}};
                    } else {
                        my %subInputs;
                        foreach my $subInput (keys(%{${$input}{INPUT}})) {
                            if(ref($subInput) !~ /^HASH$/i) {
                                $subInputs{$subInput} = $subInput;
                                next;
                            }
                            my $subValue = undef;
                            $value = ${${${$input}{INPUT}}{$subInput}}{DEFAULT} if(defined(${${${$input}{INPUT}}{$subInput}}{DEFAULT}));
                            if(!defined(${${${$input}{INPUT}}{$subInput}}{NAME})) {
                            } elsif(ref(${${${$input}{INPUT}}{$subInput}}{NAME}) !~ /^$/) {
                            } elsif(defined($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                if(!defined(${${${$input}{INPUT}}{$subInput}}{REF})) {
                                } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) =~ /^ARRAY$/i) {
                                    my %refs = map { $_ => 1 } (@{${${${$input}{INPUT}}{$subInput}}{REF}});
                                    $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}} if(defined($refs{ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})}));
                                } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) !~ /^$/) {
                                } elsif(${${${$input}{INPUT}}{$subInput}}{REF} ne ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                                } else {
                                    $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}};
                                }
                            }
                            $subInputs{$subInput} = $subValue;
                        }
                        $value = \%subInputs;
                    }
                }
            } elsif(ref(${$input}{REF}) !~ /^$/) {
            } elsif(${$input}{REF} ne ref($parameters{${$input}{NAME}})) {
            } elsif(ref($parameters{${$input}{NAME}}) !~ /^HASH$/i) {
                $value = $parameters{${$input}{NAME}};
            } else {
                if(!defined(${$input}{INPUT})) {
                    $value = $parameters{${$input}{NAME}};
                } elsif(ref(${$input}{INPUT}) !~ /^HASH$/i) {
                    $value = $parameters{${$input}{NAME}};
                } else {
                    my %subInputs;
                    foreach my $key (keys(%{${$input}{INPUT}})) {
                        if(ref($subInput) !~ /^HASH$/i) {
                            push(@subInputs, $subInput);
                            next;
                        }
                        my $subValue = undef;
                        $value = ${${${$input}{INPUT}}{$subInput}}{DEFAULT} if(defined(${${${$input}{INPUT}}{$subInput}}{DEFAULT}));
                        if(!defined(${${${$input}{INPUT}}{$subInput}}{NAME})) {
                        } elsif(ref(${${${$input}{INPUT}}{$subInput}}{NAME}) !~ /^$/) {
                        } elsif(defined($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                            if(!defined(${${${$input}{INPUT}}{$subInput}}{REF})) {
                            } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) =~ /^ARRAY$/i) {
                                my %refs = map { $_ => 1 } (@{${${${$input}{INPUT}}{$subInput}}{REF}});
                                $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}} if(defined($refs{ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})}));
                            } elsif(ref(${${${$input}{INPUT}}{$subInput}}{REF}) !~ /^$/) {
                            } elsif(${${${$input}{INPUT}}{$subInput}}{REF} ne ref($parameters{${${${$input}{INPUT}}{$subInput}}{NAME}})) {
                            } else {
                                $subValue = $parameters{${${${$input}{INPUT}}{$subInput}}{NAME}};
                            }
                        }
                        $subInputs{$subInput} = $subValue;
                    }
                    $value = \%subInputs;
                }
            }
        }
        push(@inputs, $value);
    }
    return 0 if(0 == scalar(@inputs));
    my $handle = DBI->connect(@inputs);
    return 0 if(!defined($handle));
    $self->{HANDLE} = $handle;
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'CONNECT' => 'connect');


=head2 disconnect

    if(1 == Anansi::DatabaseComponent::disconnect($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'DISCONNECT'));

    if(1 == $OBJECT->disconnect(undef));

    if(1 == $OBJECT->channel('DISCONNECT'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to perform a database disconnection.  Returns B<1> I<(one)> on success
and B<0> I<(zero)> on failure.

=cut


sub disconnect {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if(!defined($self->{HANDLE}));
    $self->{HANDLE}->disconnect();
    delete $self->{HANDLE};
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'DISCONNECT' => 'disconnect');


=head2 finish

    if(1 == Anansi::DatabaseComponent::finish($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'FINISH'));

    if(1 == $OBJECT->finish(undef));

    if(1 == $OBJECT->channel('FINISH'));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item STATEMENT I<(String, Optional)>

The name associated with a prepared SQL statement.

=back

=back

Either releases the named SQL statement preparation or all of the SQL statement
preparations.  Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.

=cut


sub finish {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    if(!defined($self->{STATEMENTS})) {
        return 0;
    } elsif(0 == scalar(keys(%{$self->{STATEMENTS}}))) {
        return 0;
    }
    if(!defined($parameters{STATEMENT})) {
        foreach my $statement (keys(%{$self->{STATEMENTS}})) {
            if(defined(${${$self->{STATEMENTS}}{$statement}}{HANDLE})) {
                eval {
                    ${${$self->{STATEMENTS}}{$statement}}{HANDLE}->finish();
                    1;
                };
            }
            delete ${$self->{STATEMENTS}}{$statement};
        }
    } elsif(ref($parameters{STATEMENT}) !~ /^$/) {
        return 0;
    } elsif(!defined(${$self->{STATEMENTS}}{$parameters{STATEMENT}})) {
        return 0;
    } elsif(!defined(${${$self->{STATEMENTS}}{$parameters{STATEMENT}}}{HANDLE})) {
        return 0;
    } else {
        eval {
            ${${$self->{STATEMENTS}}{$parameters{STATEMENT}}}{HANDLE}->finish();
            1;
        };
        delete ${$self->{STATEMENTS}}{$parameters{STATEMENT}};
    }
    delete $self->{STATEMENTS} if(0 == scalar(keys(%{$self->{STATEMENTS}})));
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'FINISH' => 'finish');


=head2 handle

    my $HANDLE = Anansi::DatabaseComponent::handle($OBJECT, undef);

    my $HANDLE = Anansi::DatabaseComponent::channel($OBJECT, 'HANDLE');

    my $HANDLE = $OBJECT->handle(undef);

    my $HANDLE = $OBJECT->channel('HANDLE');

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item handle I<(DBI::db, Optional)>

A replacement database handle.

=back

Attempts to redefine an existing database handle when a handle is supplied.
Either returns the database handle or B<undef> on failure.

=cut


sub handle {
    my ($self, $channel, $handle) = @_;
    return if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    if(defined($handle)) {
        if(defined($self->{HANDLE})) {
            $self->finish();
            $self->disconnect();
        }
        $self->{HANDLE} = $handle;
    }
    return $self->{HANDLE} if(defined($self->{HANDLE}));
    return;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'HANDLE' => 'handle');


=head2 prepare

    my $PREPARATION = if(1 == Anansi::DatabaseComponent::prepare($OBJECT, undef,
        STATEMENT => 'an associated name'
    );
    if(defined($PREPARATION));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'PREPARE',
        INPUT => [
            {
                NAME => 'someParameter'
            }
        ],
        SQL => 'SELECT abc, def FROM some_table WHERE ghi = ?',
        STATEMENT => 'another associated name'
    ));

    if(1 == $OBJECT->prepare(undef,
        INPUT => [
            {
                NAME => 'abc'
            }, {
                NAME => 'def'
            }, {
                NAME => 'ghi'
            }
        ],
        SQL => 'INSERT INTO some_table (abc, def, ghi) VALUES (?, ?, ?);',
        STATEMENT => 'yet another name'
    ));

    if(1 == $OBJECT->channel('PREPARE',
        INPUT => [
            {
                NAME => ''
            }
        ],
        SQL => '',
        STATEMENT => 'and another',
    ));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Required)>

Named parameters.

=over 4

=item INPUT I<Array, Optional>

An array of hashes.  Each hash should contain a I<NAME> key with a string value
that represents the name of a parameter to associate with the corresponding B<?>
I<(Question mark)>.  See the I<bind> method for details.

=item SQL I<(String, Optional)>

The SQL statement to prepare.

=item STATEMENT I<(String, Required)>

The name to associate with the prepared SQL statement.

=back

=back

Attempts to prepare a SQL statement to accept named parameters in place of B<?>
I<(Question mark)>s as required.  Either returns all of the preparation data
required to fulfill the SQL statement when called as a namespace method or B<1>
I<(one)> when called through a channel on success and B<0> I<(zero)> on failure.

=cut


sub prepare {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    $self->{STATEMENTS} = {} if(!defined($self->{STATEMENTS}));
    return 0 if(!defined($parameters{STATEMENT}));
    return 0 if(ref($parameters{STATEMENT}) !~ /^$/);
    if(!defined(${$self->{STATEMENTS}}{$parameters{STATEMENT}})) {
        return 0 if(!defined($parameters{SQL}));
        return 0 if(ref($parameters{SQL}) !~ /^$/);
        $parameters{SQL} =~ s/^\s*(.*)|(.*)\s*$/$1/g;
        my $questionMarks = $parameters{SQL};
        my $questionMarks = $questionMarks =~ s/\?/$1/sg;
        if(0 == $questionMarks) {
            return 0 if(defined($parameters{INPUT}));
        } elsif(!defined($parameters{INPUT})) {
            return 0;
        } elsif(ref($parameters{INPUT}) !~ /^ARRAY$/i) {
            return 0;
        } elsif(scalar(@{$parameters{INPUT}}) != $questionMarks) {
            return 0;
        } else {
            return 0 if(!$self->binding((@{$parameters{INPUT}})));
        }
        my $handle;
        eval {
            $handle = $self->{HANDLE}->prepare($parameters{SQL});
            1;
        } or do {
            $self->rollback();
            return 0;
        };
        my %statement = (
            HANDLE => $handle,
            SQL => $parameters{SQL},
        );
        $statement{INPUT} = $parameters{INPUT} if(defined($parameters{INPUT}));
        ${$self->{STATEMENTS}}{$parameters{STATEMENT}} = \%statement;
    }
    return 1 if(defined($channel));
    return ${$self->{STATEMENTS}}{$parameters{STATEMENT}};
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'PREPARE' => 'prepare');


=head2 rollback

    if(1 == Anansi::DatabaseComponent::rollback($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'ROLLBACK'));

    if(1 == $OBJECT->rollback(undef));

    if(1 == $OBJECT->channel('ROLLBACK'));

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Attempts to undo all of the database changes since the last database I<commit>.
Returns B<1> I<(one)> on success and B<0> I<(zero)> on failure.

=cut


sub rollback {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    return 0 if($self->autocommit());
    my $rollback;
    eval {
        $rollback = $self->{HANDLE}->rollback();
        1;
    } or do {
        return 0;
    };
    return 0 if(!defined($rollback));
    return 0 if(ref($rollback) !~ /^$/);
    return 0 if($rollback !~ /^[\+\-]?\d+$/);
    return 1 if($rollback);
    return 0;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'ROLLBACK' => 'rollback');


=head2 statement

    my $result = Anansi::DatabaseComponent::statement($OBJECT, undef,
        INPUT => [
            'hij' => 'someParameter',
            'klm' => 'anotherParameter'
        ],
        SQL => 'SELECT abc, def FROM some_table WHERE hij = ? AND klm = ?;',
        STATEMENT => 'someStatement',
        someParameter => 123,
        anotherParameter => 456
    );

    my $result = Anansi::DatabaseComponent::channel($OBJECT, 'STATEMENT',
        STATEMENT => 'someStatement',
        someParameter => 234,
        anotherParameter => 'abc'
    );

    my $result = $OBJECT->statement(
        undef,
        STATEMENT => 'someStatement',
        someParameter => 345,
        anotherParameter => 789
    );

    my $result = $OBJECT->channel('STATEMENT',
        STATEMENT => 'someStatement',
        someParameter => 456,
        anotherParameter => 'def'
    );

=over 4

=item self I<(Blessed Hash, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item INPUT I<(Array, Optional)>

An array of hashes with each element corresponding to an equivalent B<?>
I<(Question mark)> found within the supplied I<SQL>.  If the number of elements
is not the same as the number of B<?> I<(Question mark)>s found in the statement
then the statement is invalid.  See the I<bind> method for details.

=item SQL I<(String, Optional)>

The SQL statement to execute.

=item STATEMENT I<(String, Optional)>

The name associated with a prepared SQL statement.  This is interchangeable with
the SQL parameter but helps to speed up repetitive database interaction.

=back

=back

Attempts to execute the supplied I<SQL> with the supplied named parameters.
Either returns an array of retrieved record data or a B<1> I<(one)> on success
and a B<0> I<(zero)> on failure as appropriate to the SQL statement.

=cut


sub statement {
    my ($self, $channel, %parameters) = @_;
    return 0 if(ref($self) =~ /^(|ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    my $prepared = $self->prepare(undef, (%parameters));
    my $handle;
    if($prepared) {
        $handle = ${$prepared}{HANDLE};
        if(defined(${$prepared}{INPUT})) {
            my $bound = $self->bind(
                HANDLE => $handle,
                INPUT => ${$prepared}{INPUT},
                VALUE => \%parameters,
            );
            return 0 if(!$bound);
        }
    } else {
        eval {
            $handle = $self->{HANDLE}->prepare($parameters{SQL});
            1;
        } or do {
            $self->rollback();
            return 0;
        };
        my $questionMarks = $parameters{SQL};
        my $questionMarks = $questionMarks =~ s/\?/$1/sg;
        if(0 == $questionMarks) {
            if(defined($parameters{INPUT})) {
                $self->rollback();
                return 0;
            }
        } elsif(!defined($parameters{INPUT})) {
            $self->rollback();
            return 0;
        } elsif(ref($parameters{INPUT}) !~ /^ARRAY$/i) {
            $self->rollback();
            return 0;
        } elsif(scalar(@{$parameters{INPUT}}) != $questionMarks) {
            $self->rollback();
            return 0;
        } else {
            if(!$self->bind(
                HANDLE => $handle,
                INPUT => $parameters{INPUT},
                VALUE => \%parameters,
            )) {
                $self->rollback();
                return 0;
            }
        }
    }
    eval {
        $handle->execute();
        1;
    } or do {
        $handle->rollback();
        return 0;
    };
    if(!defined($handle->{NUM_OF_FIELDS})) {
        return 1;
    } elsif(undef == $handle->{NUM_OF_FIELDS}) {
        return 1;
    } elsif(0 == $handle->{NUM_OF_FIELDS}) {
        return 1;
    }
    my $result = [];
    while(my $row = $handle->fetchrow_hashref()) {
        push(@{$result}, $row);
    }
    $handle->finish() if(!$prepared);
    return $result;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'STATEMENT' => 'statement');


=head2 validate

    if(1 == Anansi::DatabaseComponent::validate($OBJECT, undef));

    if(1 == Anansi::DatabaseComponent::channel($OBJECT, 'VALIDATE_AS_APPROPRIATE'));

    if(1 == Anansi::DatabaseComponent->validate(undef, DRIVERS => ['some::driver::module', 'anotherDriver']));

    if(1 == Anansi::DatabaseComponent->channel('VALIDATE_AS_APPROPRIATE'));

    if(1 == $OBJECT->validate(undef, DRIVER => 'Example'));

    if(1 == $OBJECT->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'Example'));

    if(1 == Anansi::DatabaseComponent->validate(undef, DRIVER => 'Example', DRIVERS => 'some::driver'));

    if(1 == Anansi::DatabaseComponent->channel('VALIDATE_AS_APPROPRIATE', DRIVER => 'Example'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item DRIVER I<(String, Optional)>

Either the namespace of a database driver or the name of a database driver that
should be used.

=item DRIVERS I<(Array B<or> String, Optional)>

An array of strings or a single string containing either the namespace of a
valid database driver or the name of a database driver that should be looked for
among the installed modules.

=back

=back

Generic validation for whether a database should be handled by a component.  If
the driver name is supplied then an attempt will be made to use that driver as
long as it matches any of the acceptable B<DRIVERS>, otherwise one of the
acceptable B<DRIVERS> will be tried or a generic driver if none have been
supplied.  Returns B<1> I<(one)> for valid and B<0> I<(zero)> for invalid.

=cut


sub validate {
    my ($self, $channel, %parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    my %modules = Anansi::Actor->modules();
    return 0 if(!defined($modules{'Bundle::DBI'}));
    if(!defined($parameters{DRIVER})) {
        if(defined($parameters{DRIVERS})) {
            $parameters{DRIVERS} = [( $parameters{DRIVERS} )] if(ref($parameters{DRIVERS}) =~ /^$/);
            return 0 if(ref($parameters{DRIVERS}) !~ /^ARRAY$/i);
            my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
            foreach my $DRIVER (@{$parameters{DRIVERS}}) {
                return 0 if(ref($DRIVER) !~ /^$/);
                return 1 if(defined($modules{$DRIVER}));
                return 1 if(defined($modules{'DBD::'.$DRIVER}));
                return 1 if(defined($modules{'Bundle::DBD::'.$DRIVER}));
                return 1 if(defined($reduced{lc($DRIVER)}));
                return 1 if(defined($reduced{lc('DBD::'.$DRIVER)}));
                return 1 if(defined($reduced{lc('Bundle::DBD::'.$DRIVER)}));
            }
            return 0;
        } elsif(!defined($modules{'Bundle::DBD'})) {
            return 0;
        }
    } elsif(ref($parameters{DRIVER}) !~ /^$/) {
        return 0;
    } elsif(defined($parameters{DRIVERS})) {
        $parameters{DRIVERS} = [( $parameters{DRIVERS} )] if(ref($parameters{DRIVERS}) =~ /^$/);
        return 0 if(ref($parameters{DRIVERS}) !~ /^ARRAY$/i);
        my %DRIVERS;
        $DRIVERS{$parameters{DRIVER}} = 1;
        $DRIVERS{'DBD::'.$parameters{DRIVER}} = 1;
        $DRIVERS{'Bundle::DBD::'.$parameters{DRIVER}} = 1;
        $DRIVERS{lc($parameters{DRIVER})} = 1;
        $DRIVERS{lc('DBD::'.$parameters{DRIVER})} = 1;
        $DRIVERS{lc('Bundle::DBD::'.$parameters{DRIVER})} = 1;
        my $found = 0;
        foreach my $DRIVER (@{$parameters{DRIVERS}}) {
            return 0 if(ref($DRIVER) !~ /^$/);
            $found = 1;
            last if(defined($DRIVERS{$DRIVER}));
            last if(defined($DRIVERS{'DBD::'.$DRIVER}));
            last if(defined($DRIVERS{'Bundle::DBD::'.$DRIVER}));
            last if(defined($DRIVERS{lc($DRIVER)}));
            last if(defined($DRIVERS{lc('DBD::'.$DRIVER)}));
            last if(defined($DRIVERS{lc('Bundle::DBD::'.$DRIVER)}));
            $found = 0;
        }
        return 0 if(!$found);
        my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
        foreach my $DRIVER (@{$parameters{DRIVERS}}) {
            return 1 if(defined($modules{$DRIVER}));
            return 1 if(defined($modules{'DBD::'.$DRIVER}));
            return 1 if(defined($modules{'Bundle::DBD::'.$DRIVER}));
            return 1 if(defined($reduced{lc($DRIVER)}));
            return 1 if(defined($reduced{lc('DBD::'.$DRIVER)}));
            return 1 if(defined($reduced{lc('Bundle::DBD::'.$DRIVER)}));
        }
        return 0;
    } elsif(defined($modules{$parameters{DRIVER}})) {
    } elsif(defined($modules{'DBD::'.$parameters{DRIVER}})) {
    } elsif(!defined($modules{'Bundle::DBD::'.$parameters{DRIVER}})) {
        my %reduced = map { lc($_) => $modules{$_} } (keys(%modules));
        if(defined($reduced{lc($parameters{DRIVER})})) {
        } elsif(defined($reduced{lc('DBD::'.$parameters{DRIVER})})) {
        } elsif(!defined($reduced{lc('Bundle::DBD::'.$parameters{DRIVER})})) {
            return 0;
        }
    }
    return 1;
}

Anansi::Component::addChannel('Anansi::DatabaseComponent', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;
