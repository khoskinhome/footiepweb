package FootiePWeb;
use Dancer ':syntax';

use Dancer::Plugin::Database;

##use Digest::SHA;
use Digest::SHA qw(sha512_hex);

#use Dancer::Logger;
#use Dancer::Config    'setting';
#use Dancer::FileUtils 'path';
#use Dancer::ModuleLoader;

our $VERSION = '0.1';

get '/' => sub {
    template 'main' => { karlvar => "itsakarl!" };
};

=pod
##########################################################
Standard-user can
#################
) request a login ( POST )
) Login (POST)
) change their password (POST)
) view their predictions (GET)
) add new predictions (POST) (cannot edit predictions, it is a publish and be damned game)
) view other people's predictions if they've entered their own ones. (GET)
) view the league table for the competitions (GET)
=cut

hook 'before' => sub {
    if (! session('email') && request->path_info !~ m{^/login} && request->path_info !~ m{^/register}) {
        var requested_path => request->path_info;
        request->path_info('/login');
    }
};

get '/login' => sub {
    # Display a login page; the original URL they requested is available as
    # vars->{requested_path}, so could be put in a hidden field in the form
    template 'login', { path => vars->{requested_path} };
};

get '/logout' => sub {
    #session email => '';
    #session nickname => '';
    # instead of the above , maybe use :-
    session->destroy;

    template 'login', { path => vars->{requested_path} };
};

post '/login' => sub {
    # Validate the user's email and password they supplied

    my $sth = database->prepare(
       'select * from user where email = ? or nickname = ? ',
    );

#    print STDERR "\n\n /login : params nickname == ".params->{nickname}."\n";

    $sth->execute( params->{email} || '', params->{nickname} || '' );
#    template 'display_widget', { widget => $sth->fetchrow_hashref };

    my $sha_param_password = sha512_hex(params->{pass});
    if (params->{email} eq 'stderr') {
        print STDERR "\n\n stderr !! : sha_param_password == ".$sha_param_password."\n";
    }

    if ( my $rowrh = $sth->fetchrow_hashref ) {
        if ($rowrh->{password_sha} eq $sha_param_password ) {
            print STDERR "\n\nlogin for ".params->{email}." with sha_param_password == ".$sha_param_password."\n";

            session email    => $rowrh->{email} ;
            session nickname => $rowrh->{nickname} ;

            return redirect params->{path} || '/';
        }
        else { # TODO rm this section. eventually.
            print STDERR "\n\n couldn't login ".params->{email}." : sha_param_password == ".$sha_param_password."\n";
        }
    }
    redirect '/login?failed=1';

};

## forgot-password page :-
get '/forgot-password'  => sub { template 'forgot-password' };
post '/forgot-password' => sub {
    return template 'error-message' => { error_message => "forgot password hasn't been completed yet. to be written." };
};

# register page :-
get '/register' => sub { template 'register' };
post '/register' => sub {

    my $password_okay = _param_password_is_okay();
    return template 'error-message' => { error_message => $password_okay } if lc($password_okay) ne 'ok';

    #########################
    # validate email
    if ( length params->{email} < 6 ) {
        return template 'error-message' => { error_message => 'email is less than 6 characters long. choose a longer one.' };
    }
    # REALLY NAIVE email validity checking ( well its better than nothing )
    if ( params->{email} !~ /@/ ) {
        return template 'error-message' => { error_message => 'email doesn\'t have an @ sign in it.' };
    }

    # TODO proper email checking  . 
    # Need to send a validate email that creates a checking_token_emailed in the 'user' table
    # This email will have a hyperlink that comes back to this app with then endpoint something like :-
    #
    # http://app-hostname/register-validate/?token=$checking_token_emailed
    # this will then be confirmed.

    my $sth = database->prepare(
       'select * from user where email = ? ',
    );
    $sth->execute(params->{email} );
    if ( my $rowrh = $sth->fetchrow_hashref ) {
        return template 'error-message' => { error_message => 'that email address has already been registered.' };
    }
    #########################
    # validate nickname
    if ( length params->{nickname} < 2 ) {
        return template 'error-message' => { error_message => 'nickname is less than 2 characters long. choose a longer one.' };
    }

    $sth = database->prepare(
       'select * from user where nickname = ? ',
    );

    $sth->execute( params->{nickname} );
    if ( my $rowrh = $sth->fetchrow_hashref ) {
        return template 'error-message' => { error_message => 'that nickname has already been registered.' };
    }
    #########################
    my $sha_param_password = sha512_hex(params->{pass});

    #########################
    $sth = database->prepare(
       'insert into user (email, nickname, password_sha) values ( ? , ? , ? ) ',
    );

    $sth->execute( params->{email}, params->{nickname}, $sha_param_password );

    # TODO. We really should make the user confirm the email account.
    # i.e. send an email to them with a checking_token_emailed ( at a time checking_token_emailed_gmt_date )

    session email => params->{email};
    session nickname => params->{nickname};
    return redirect params->{path} || '/';
};

#####################
# get the change-password page :-
get '/change-password' => sub { template 'change-password' };
post '/change-password' => sub {
    my $password_okay = _param_password_is_okay();
    return template 'error-message' => { error_message => $password_okay } if lc($password_okay) ne 'ok';

    my $sha_param_password = sha512_hex(params->{pass});

    my $sth = database->prepare(
       'update user set password_sha = ? where email = ? ',
    );
    $sth->execute( $sha_param_password , session('email') );

    #session email => '';
    #session nickname => '';
    session->destroy;
    return template 'error-message' => { error_message => "you will now have to login again" };
};

sub _param_password_is_okay {
    #    returns "ok" , or an "error_message"
    # used for validating a register or change-password event.
    # i.e. where we have the params "pass" and "pass2"

    #########################
    # validate passwords
    if ( params->{pass} ne params->{pass2} ) {
        return 'passwords do not match up';
    }
    if ( length (params->{pass}) < 6 ) {
        return 'passwords is less than 6 characters long. choose a longer one.';
    }
    return 'ok';
}

#####################
get '/change-other-password' => sub {

    if ( ! current_session_user_is_admin() ) {
        return template 'error-message' => { error_message => "you aren't an Admin user. You cannot change other people's passwords" };
    }
    template 'change-other-password' ;
};

post '/change-other-password' => sub {

    if ( ! current_session_user_is_admin() ) {
        return template 'error-message' => { error_message => "you aren't an Admin user. You cannot change other people's passwords" };
    }

    if ( params->{'email-other'} && params->{'nickname-other'} ) {
        return template 'error-message' => { error_message => "please only specifiy either the other-email or the other-nickname, and not both of them when you are trying to change someone else's password" };
    }

    ######
    my $password_okay = _param_password_is_okay();
    return template 'error-message' => { error_message => $password_okay } if lc($password_okay) ne 'ok';

    ######
    my $sth = database->prepare(
       'select * from user where email = ? or nickname = ? ',
    );

    my $other_email ;
    $sth->execute( params->{'email-other'} || '', params->{'nickname-other'} || '' );
    if ( my $rowrh = $sth->fetchrow_hashref ) {
        $other_email = $rowrh->{email};
    }

    if ( ! $other_email ){
        return template 'error-message' => { error_message => "couldn't find the user" } ;
    }

    my $sha_param_password = sha512_hex(params->{pass});

    my $sth = database->prepare(
       'update user set password_sha = ? where email = ? ',
    );
    $sth->execute( $sha_param_password , $other_email );

    return template 'error-message' => { error_message => "changed password for other user with the email address $other_email" };


};

sub current_session_user_is_admin {
    # this will return 1 if the current session user is an admin.

    return 0 if ! session('email');

    my $sth = database->prepare(
       'select * from user where email = ?',
    );

    $sth->execute(session('email'));

    if ( my $rowrh = $sth->fetchrow_hashref ) {
        return $rowrh->{is_admin};
    }
    return 0;
}

hook 'before_template_render' => sub {
    my $tokens = shift ;

    print STDERR "\n\n before template render == " . current_session_user_is_admin()."\n\n";
    $tokens->{user_is_admin} = current_session_user_is_admin();
};

##########################################################
get  '/predictions' => sub { template 'predictions'};
post '/predictions' => sub {

    return template 'error-message' => { error_message => "entering your predictions hasn't been completed yet. to be written." };
}

;

get  '/league' => sub { template 'league' };


=pod
##########################################################
Admin-user can
##############
) login (POST)
) change their password (POST)

) View games (GET)
) Add/Edit/Delete a game (POST)

) view competitions
) Add/Edit/Delete competitions (POST)

) view game-competitions (GET)
) add or delete games to competitions (POST)

) view user-competitions (GET)
) Add/Delete users to competitions (POST)


Tables
######
######################################
mysql> create table game (
    id INT NOT NULL AUTO_INCREMENT,
    name varchar(255) not null,
    score_90m_home int not null,
    score_90m_away int not null,
    kickoff_gmt date not null,
    cup_result enum('home-win', 'away-win'),
    needs_result boolean not null,
    tournament_id int not null,
    primary key( id )
);

game => {
    id                   => 'primary-key',
    name                 => 'string' , # something like "Arsenal v Liverpool"
    score_90m_home       => 'int',
    score_90m_away       => 'int',
    kickoff_gmt          => 'datetime',
    cup_result           => 'enum',  # home-win OR away-win, only needs setting if the score after 90m was a draw, and the needs_result boolean is true.
    needs_result         => 'boolean', # If a game needs a result, i.e  it will go to extra-time and possibly penalties, this is set as true.
    real_competition     => 'enum', # Premier League, world cup, fa-cup, league-cup, champ-league etc ....
},
#####################################
mysql > create table prediction (
    id INT NOT NULL AUTO_INCREMENT,
    game_id INT NOT NULL,
    user_id INT NOT NULL,
    score_90m_home int not null,
    score_90m_away int not null,
    cup_result enum('home-win', 'away-win'),
    primary key( id )
    );

prediction => {
    id                   => 'primary-key',
    game_id              => 'foreign-key',
    user_id              => 'foreign-key',
    score_90m_home       => 'int',
    score_90m_away       => 'int',
    cup_result           => 'enum',  # home-win OR away-win, only needs setting if the score after 90m was a draw, and the needs_result boolean is true.

},

#####################################

mysql > create table user (
    id INT NOT NULL AUTO_INCREMENT,
    nickname varchar(255) not null,
    email varchar(255) not null,
    confirmed_email boolean not null,
    is_admin boolean not null,
    password_sha varchar(1024) not null,
    checking_token_emailed varchar(1024) NULL ,
    checking_token_emailed_gmt_date date null ,
    primary key ( id ),
    unique (email),
    unique (nickname)
);

user => {
    id              => 'primary-key' ,
    nickname        => 'string' ,
    email           => 'string' ,
    password_sha    => 'string' ,
`   confirmed_email => 'boolean' ,
    is_admin        => 'boolean' ,
},
######################################


# tournament is the REAL tournament, i.e FA-Premier_League, World-Cup, Spanish-La-Liga etc.
create table tournament (     id INT NOT NULL AUTO_INCREMENT,     name varchar(255) not null,     primary key ( id ) );

tournament => {
    id                   => 'primary-key',
    name                 => 'string' , # Premier-League, World Cup, FA-Cup etc....
},
######################################

# Competition is the name of the Competition within footiepweb 

create table competition (     id INT NOT NULL AUTO_INCREMENT,     name varchar(255) not null,     primary key ( id ) );
competition => {
    id                   => 'primary-key',
    name                 => 'string' ,
},
######################################

create table user_competition (
    id INT NOT NULL AUTO_INCREMENT,
    user_id int not null,
    competition_id int not null,
    primary key ( id ) );

'user_competition' => {
    id                   => 'primary-key',
    user_id              => 'foreign-key',
    competition_id       => 'foreign-key',
},

######################################

'game_competition' => {
    id                   => 'primary-key',
    game_id              => 'foreign-key',
    competition_id       => 'foreign-key',
}

######################################

=cut

true;
