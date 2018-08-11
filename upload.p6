#!/usr/bin/env perl6

use JSON::Fast;

sub mixtape_parse(Str $mix --> Str) {
	my %res = from-json $mix;
	unless %res<success> {
		die "mixtape.moe error " ~ %res;
	}

	return %res<files>[0]<url>;
}
sub id($x) { $x; }

sub uploader(Str $url, Str $param, Str $fname --> Str) {
	my $ret = (run qqx/curl -sS -F "$param=@$fname" $url/).command[0];
	$ret ~~ s/\n//;
	return $ret;
}

sub print-and-copy(Str $s) {
	say $s;
	shell "echo \"$s\"|xsel -i -b";
}

sub manage_uploads(Str $url, Str $param, &postprocess=&id) {
	my @uploads;
	if (@*ARGS.elems == 1) {
		@uploads.push("-");
	} else {
		@uploads = @*ARGS[1 .. *];
	}

	for @uploads -> $x {
		# need a mutable copy
		my $y = $x;

		# if it doesn't have a files extension, force curl to name it 't.txt' so some file hosts will add a file extension of .txt
		if $y.split('/').tail.split('.').elems == 1 {
			$y = "$y;filename=t.txt";
		}
		print-and-copy(postprocess(uploader($url, $param, $y)));
	}
}

given @*ARGS[0] {
	when "0x0" { manage_uploads("https://0x0.st", "file"); }
	when "mixtape" { manage_uploads("https://mixtape.moe/upload.php", "files[]", &mixtape_parse); }
	when "sprunge" { manage_uploads("http://sprunge.us", "sprunge"); }
	when "ix" { manage_uploads("http://ix.io", "f:1"); }
	when Str { die "Unknown host @*ARGS[0]"; }
	when Any { die "No host given!"; }
}