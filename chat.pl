#!/usr/bin/perl -w

use Config::Simple;
use Net::WebSocket::Server;
use DBI;

$cfg = new Config::Simple('chat_config.cfg');

Net::WebSocket::Server->new(
    listen => $cfg->param('listen_port'),
    on_connect => sub {
        my ($serv, $conn) = @_;
        $conn->on(
            utf8 => sub {
                my ($conn, $msg) = @_;
                my ($srv,$chat_user, $user_msg) = split(":", $msg);
                if ($srv eq "msg") {
                    historyadd($chat_user, $user_msg);
                    $_->send_utf8($chat_user . ":" . $user_msg) for $conn->server->connections;
                } else {
                    $msg = gethistory();
                    $conn->send_utf8($msg);
                }
               
            },
        );
    },
)->start;


sub historyadd { 
    
    my $name=shift;
    my $msg=shift;
    
    my $conn_line = "DBI:Pg:dbname=" . $cfg->param('db_name') . ";host=" . $cfg->param('db_host');
    my $myConnection = DBI->connect($conn_line, $cfg->param('db_user'), $cfg->param('db_pass'));
    
    my $query = $myConnection->prepare("INSERT INTO history (username,message) VALUES (?,?)");
    my $result = $query->execute($name, $msg);
    $query->finish();
    $myConnection->disconnect;
    return;
    
}

sub gethistory { 
    
    my $conn_line = "DBI:Pg:dbname=" . $cfg->param('db_name') . ";host=" . $cfg->param('db_host');
    my $myConnection = DBI->connect($conn_line, $cfg->param('db_user'), $cfg->param('db_pass'));

    my $query = $myConnection->prepare("SELECT username,message FROM history WHERE date_created='NOW()'");
    my $result = $query->execute();
    if ($result != '0E0') {
        my $msg = "";
        while (my $item = $query->fetchrow_hashref) {
            $msg .=   $item->{username} . ":" . $item->{message} . "<br/>";            
        }
        return $msg;
    }
    $query->finish();
    $myConnection->disconnect;
    return;
    
}
