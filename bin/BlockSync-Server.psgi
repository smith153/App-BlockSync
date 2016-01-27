#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use App::BlockSync::Server;
App::BlockSync::Server->to_app;
