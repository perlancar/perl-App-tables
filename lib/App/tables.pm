package App::tables;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
#IFUNBUILT
use strict;
use warnings;
#END IFUNBUILT

#use PerlX::Maybe;

our %SPEC;

our %arg0_table = (
    table => {
        summary => 'Tables::* module name without the prefix, e.g. Locale::US::States '.
            'for Tables::Locale::US::States',
        schema => 'perl::modname*',
        req => 1,
        pos => 0,
        completion => sub {
            my %args = @_;
            require Complete::Module;
            Complete::Module::complete_module(
                word => $args{word},
                ns_prefix => 'Tables',
            );
        },
    },
);

our %argopt_table_args = (
    table_args => {
        summary => 'Arguments to pass to Tables::* class constructor',
        schema => [hash => of=>'str*'],
        cmdline_aliases => {A=>{}},
    },
);

$SPEC{list_installed_tables_modules} = {
    v => 1.1,
    summary => 'List installed Tables::* modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_installed_tables_modules {
    require Module::List::Tiny;
    my %args = @_;

    my $mods = Module::List::Tiny::list_modules(
        'Tables::', {list_modules=>1, recurse=>1});
    my @rows;
    for my $mod (sort keys %$mods) {
        (my $table = $mod) =~ s/^Tables:://;
        push @rows, {table=>$table};
    }

    @rows = map { $_->{table} } @rows unless $args{detail};

    [200, "OK", \@rows];
}

$SPEC{show_tables_module} = {
    v => 1.1,
    summary => 'Show contents of a Tables::* module',
    args => {
        %arg0_table,
        %argopt_table_args,
        as => {
            schema => ['str*', in=>['aoaos', 'aohos', 'csv']],
            default => 'aoaos',
        },
    },
};
sub show_tables_module {
    my %args = @_;

    my $as = $args{as} // 'aoaos';

    my $mod = "Tables::$args{table}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $table = $mod->new(%{ $args{table_args} // {} });

    if ($as eq 'csv') {
        return [200, "OK", $table->as_csv, {'cmdline.skip_format'=>1}];
    }

    my @rows;
    while (1) {
        my $row = $as eq 'aohos' ? $table->get_row_hashref : $table->get_row_arrayref;
        last unless $row;
        push @rows, $row;
    }
    [200, "OK", \@rows, {'table.fields'=>scalar $table->get_column_names}];
}

$SPEC{get_tables_module_info} = {
    v => 1.1,
    summary => 'Show information about a Tables::* module',
    args => {
        %arg0_table,
    },
};
sub get_tables_module_info {
    my %args = @_;

    my $mod = "Tables::$args{table}";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $table = $mod->new(%{ $args{table_args} // {} });

    return [200, "OK", {
        table => $args{table},
        module => $mod,
        column_count => $table->get_column_count,
        column_names => $table->get_column_names,
        row_count => $table->get_row_count,
    }];
}

1;
# ABSTRACT: Manipulate Tables::* modules

=head1 SEE ALSO

L<Tables>

L<td> from L<App::td>
