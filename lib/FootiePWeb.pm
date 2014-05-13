package FootiePWeb;
use Dancer ':syntax';

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
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
    if (! session('user') && request->path_info !~ m{^/login}) {
        var requested_path => request->path_info;
        request->path_info('/login');
    }
};
 
get '/login' => sub {
    # Display a login page; the original URL they requested is available as
    # vars->{requested_path}, so could be put in a hidden field in the form
    template 'login', { path => vars->{requested_path} };
};
 
post '/login' => sub {
    # Validate the username and password they supplied
    if (params->{user} eq 'bob' && params->{pass} eq 'letmein') {
        session user => params->{user};
        redirect params->{path} || '/';
    } else {
        redirect '/login?failed=1';
    }
};


# get the request-login page :-
get '/user/request-login' => sub { template 'request-login' };

# submit the request-password
post '/user/request-login' => sub { 

};

# get the login page :-
#get '/user/login' => sub { template 'login' };

# submit the password
#post '/user/login' => sub { };

# get the change-password page :-
get '/user/change-password' => sub { template 'change-password' };
# submit the password
post '/user/change-password' => sub { 

};

get  '/user/predictions' => sub { template 'predictions'};
post '/user/predictions' => sub {}

;

get  '/user/league' => sub { template 'league' };


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
