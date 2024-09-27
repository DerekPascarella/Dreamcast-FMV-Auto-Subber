#!/usr/bin/perl
#
# Dreamcast FMV Auto-Subber v1.0
# A utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.
#
# Written by Derek Pascarella (ateam)

# Modules.
use strict;
use File::Copy;

# Set version number.
my $version = "1.0";

# Set header used in CLI messages.
my $cli_header = "\nDreamcast FMV Auto-Subber " . $version . "\nA utility to batch re-encode Dreamcast SFD videos with baked-in subtitles.\n\nWritten by Derek Pascarella (ateam)\n\n";

# Check for existence of helper utilities.
my @helper_utilities =
(
	"adxencd.exe",
	"demux.exe",
	"ffmpeg.exe",
	"ffprobe.exe",
	"legaladx.exe",
	"Sfdmux.dll",
	"sfdmux.exe"
);

# Perform helper utility check.
foreach my $file (@helper_utilities)
{
	# Terminate program if missing.
	if(!-e "helper_utilities/" . $file)
	{
		print $cli_header;
		print STDERR "One or more files is missing from the \"helper_utilities\" folder: " . $file;
		print "\n\nPress Enter to exit.\n";
		<STDIN>;
		
		exit;
	}
}

# Throw error if configuration INI doesn't exist.
if(!-e "config.ini")
{
	print $cli_header;
	print STDERR "Configuration file \"config.ini\" missing from root folder.";
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit;
}

# Store hash of configuration options from INI.
my %config_options = &read_ini("config.ini");

# Perform configuration INI validation.
my($valid_ini, $ini_error_message) = &validate_ini(%config_options);

# Throw error if configuration INI contains invalid or missing options.
if(!$valid_ini)
{
	print $cli_header;
	print STDERR $ini_error_message;
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit; 
}

# Status message.
print $cli_header;

# Read contents of "input" folder and store each SFD file name in element of array.
opendir(my $dh, "input");
my @input_files = grep { /\.sfd$/i && -f "input/" . $_ } readdir($dh);
closedir($dh);

# Throw error if no SFD files found in "input" folder.
if(!@input_files)
{
	print $cli_header;
	print STDERR "No SFD files found in \"input\" folder.";
	print "\n\nPress Enter to exit.\n";
	<STDIN>;
	
	exit; 
}

# Status message.
print scalar(@input_files) . " video(s) found in \"input\" folder.\n\n";

# Copy each helper utility to "input" folder.
foreach my $file (@helper_utilities)
{
	copy("helper_utilities/" . $file, "input");
}

# Change to "input" folder.
chdir("input");

# Iterate through and process each file.
foreach my $file_sfd (@input_files)
{
	# Status message.
	print "-> " . $file_sfd . "\n";

	# Replace file extension for to generate SRT subtitle file name.
	my $file_srt = $file_sfd =~ s/\.[^.]+$/.SRT/r;

	# No accompanying SRT subtitle file found.
	if(!-e $file_srt)
	{
		print "   - Accompanying subtitle file \"" . $file_sfd . "\" not found, skipping.\n";
	}
	# Otherwise, continue processing video.
	else
	{
		# Status message.
		print "   - Constructing ffmpeg command...\n";

		# Begin constructing ffmpeg command.
		my $ffmpeg_command =  "ffmpeg.exe -i m2v.m2v -vcodec mpeg1video ";
		   $ffmpeg_command .= "-b:v " . $config_options{'bitrate'} . " -maxrate " . $config_options{'bitrate'} . " -minrate " . $config_options{'bitrate'} . " -bufsize " . $config_options{'bitrate'} . " -muxrate " . $config_options{'bitrate'} . " ";
		   $ffmpeg_command .= "-s 320x224 -an -vf \"subtitles=" . $file_srt . ":force_style='Fontname=" . $config_options{'font_face'} . ",Fontsize=" . $config_options{'font_size'} . ",Bold=";

		# Set bold text.
		if($config_options{'font_bold'} eq "yes")
		{
			$ffmpeg_command .= "1";
		}
		# Set regular text.
		else
		{
			$ffmpeg_command .= "0";
		}
		
		# Continue constructing ffmpeg command.
		$ffmpeg_command .= ",OutlineColour=&H" . $config_options{'outline_color'} . "&,Outline=" . $config_options{'outline_strength'} . ",MarginV=" . $config_options{'margin_vertical'} . ",MarginL=" . $config_options{'margin_left'} . ",MarginR=" . $config_options{'margin_right'};

		# Store results of ffprobe to check video dimensions to ensure proper subtitle scaling.
		my $dimension_test = `ffprobe.exe -v quiet -select_streams v:0 -show_entries stream=width,height -of csv=p=0 $file_sfd 2>NUL`;

		# Use half-scale subtitle text for narrow video resolutions.
		if($dimension_test =~ /320,448/)
		{
			$ffmpeg_command .= ",ScaleX=0.5";
		}

		# Finish constructing ffmpeg command.
		$ffmpeg_command .= "'\" m1v.m1v";

		# Status message.
		print "   - Demuxing original SFD...\n";
		
		# Demux SFD.
		system "demux.exe $file_sfd demux > NUL 2>&1";
		rename("demux_c0.m2a", "m2a.m2a");
		rename("demux_e0.m2v", "m2v.m2v");

		# Status message.
		print "   - Converting audio stream to WAV...\n";

		# Convert M2A to WAV.
		system "ffmpeg.exe -i m2a.m2a -c:a pcm_s16le -ar 44100 -ac 2 wav.wav > NUL 2>&1";
		unlink("m2a.m2a");

		# Status message.
		print "   - Converting WAV to SFA...\n";

		# Convert WAV to SFA.
		system "adxencd.exe wav.wav adx.adx > NUL 2>&1";
		unlink ("wav.wav");
		system "legaladx.exe adx.adx sfa.sfa > NUL 2>&1";
		unlink("adx.adx");

		# Status message.
		print "   - Encoding new video with subtitles...\n";

		# Encode new video with baked-in subtitles.
		system "$ffmpeg_command > NUL 2>&1";
		unlink("m2v.m2v");

		# Status message.
		print "   - Remuxing new video with original audio stream...\n";
		
		# Remux video and original audio stream.
		system "sfdmux.exe -V=m1v.m1v -A=sfa.sfa -S=sfd.sfd > NUL 2>&1";
		unlink("sfa.sfa");
		unlink("m1v.m1v");

		# Status message.
		print "   - Moving new SFD to \"output\" folder...\n";

		# Move new SFD to "output" folder.
		rename("sfd.sfd", "../output/" . $file_sfd);
	}
}

# Return back to root folder.
chdir("..");

# Delete each helper utility from "input" folder.
foreach my $file (@helper_utilities)
{
	unlink("input/" . $file);
}

# Status message.
print "\nProcess complete!\n\n";
print "Press Enter to exit.\n";
<STDIN>;

# Subroutine to read configuration INI file and return a hash of key-value pairs.
sub read_ini
{
	# Store input parameter of INI file name.
	my $file = $_[0];
	
	# Declare hash.
	my %config;

	# Open configuration INI.
	open(my $fh, '<', $file) or die "Could not open file '$file' $!";

	# Read through file.
	while(my $line = <$fh>)
	{
		# Remove newline.
		chomp $line;

		# Skip empty lines and comments.
		next if $line =~ /^\s*$/;
		next if $line =~ /^\s*#/;

		# Split each line into key and value.
		if($line =~ /^\s*([^=]+?)\s*=\s*(.+?)\s*$/)
		{
			# Store key-value pair into hash.
			my ($key, $value) = ($1, $2);
			$config{$key} = $value;
		}
	}

	# Close configuration INI.
	close($fh);

	# Return hash.
	return %config;
}

# Subroutine to validate the hash generated from configuration INI.
sub validate_ini
{
	# Store input paramater of configuration hash.
	my %config = @_;

	# Store list of string type keys.
	my @string_keys = ('font_face');

	# Store list of integer type keys.
	my @integer_keys = ('font_size', 'outline_color', 'outline_strength', 'margin_vertical', 'margin_left', 'margin_right', 'bitrate');

	# Validate bold setting.
	if($config{'font_bold'} ne "yes" && $config{'font_bold'} ne "no")
	{
		return(0, "Configuration option \"font_bold\" should be \"yes\" or \"no\" (is currently set to \"" . $config{'font_bold'} . "\").");
	}

	# Validate string keys.
	foreach my $key (@string_keys)
	{
		# Key exists.
		if(exists $config{$key})
		{
			unless($config{$key} =~ /^[\w\s]+$/)
			{
				return(0, "Configuration option \"" . $key . "\" should be a string (is currently set to \"" . $config{$key} . "\").");
			}
		}
		# Key does not exist.
		else
		{
			return(0, "Configuration option \"" . $key . "\" is missing.");
		}
	}

	# Validate integer keys.
	foreach my $key (@integer_keys)
	{
		# Key exists.
		if(exists $config{$key})
		{
			unless($config{$key} =~ /^\d+$/)
			{
				return(0, "Configuration option \"" . $key . "\" should be an integer number (is currently set to \"" . $config{$key} . "\").");
			}
		}
		# Key does not exist.
		else
		{
			return(0, "Configuration option \"" . $key . "\" is missing.");
		}
	}

	# If all configuration keys are valid, return success without error message.
	return(1, "");
}