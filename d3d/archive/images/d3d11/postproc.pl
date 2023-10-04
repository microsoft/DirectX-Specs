
#-----------------------------------------------------------------------------
#
# usage/globals
#
$usage = "postproc <html_input_file_name> <constant_listing_input_file_name> [-noddi] [-noint] [-noapi] [-norem] [-nodel10To11]\n";
$ifile = "";
$ifile_constants = "";
$no_del10To11 = 0;
$no_ddi = 0;
$no_int = 0;
$no_api = 0;
$no_rem = 0;
$past_title = 0;

#-----------------------------------------------------------------------------
#
# Parse command line
#
$ifile = shift (@ARGV);
$ifile_constants = shift (@ARGV);
while (@ARGV)
{
    $_ = shift (@ARGV);
    if (/^-noddi/)
    {
        $no_ddi = 1;
    }
    elsif (/^-noapi/)
    {
        $no_api = 1;
    }
    elsif (/^-noint/)
    {
        $no_int = 1;
    }
    elsif (/^-norem/)
    {
        $no_rem = 1;
    }
    elsif (/^-nodel10To11/)
    {
        $no_del10To11 = 1;
    }
    else
    {
        print "Usage: $usage\n";
        exit;
    }
}

if( $ifile eq "" ) {die "No input specified\n";}
if( $ifile_constants eq "" ) {die "No input constants file specified\n";}

#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
#
# HTML parser package
#
{
    package HTMLParse;
    use base 'HTML::Parser';

    $in_ddi = 0;
    $in_api = 0;
    $in_int = 0;
    $in_rem = 0;
    $in_del10To11 = 0;
    $InHeader = 0;  # not in header if 0, else in header level 'n'
    $Text = "";
    $HeaderLevel = { 0, 0, 0, 0, 0, 0 };
    @HeaderList;
    $HeaderCount = 0;
    $Messages;
    $MessageCount = 0;
    $tocLong = "Table of Contents";
    $tocShort = "Condensed Table of Contents";
    $LinkSectionTag = "_#_#_#_INSERT_SECTION_NUMBER_#_#_#_"; # local to this script, don't use directly in html
    $UseUnlabeledLink = "##USE_UNLABELED_LINK##"; # if link text (visible part) has this in it, don't print a section label (e.g. (3.1.3))
                                              # This is typically for high density links where the labels would hurt readability.
                                              # Note this constant is removed so it doesn't appear in the output.
    $OutsideLink = "##OUTSIDE_LINK##"; # if link text (visible part) has this in it, adds link to list of declared external links (so warning on external links is not displayed)
    $InsertTOCLong = "##INSERT_LONG_TABLE_OF_CONTENTS##"; # this text is replaced with a long table of contents
    $InsertTOCShort = "##INSERT_SHORT_TABLE_OF_CONTENTS##"; #this text is replaced with a short table of contents
    $InsertTOCChapter = "##INSERT_CHAPTER_TABLE_OF_CONTENTS##"; #this text is replaced with a table of contents for the current chapter
    $InsertTOCSection = "##INSERT_H2_TABLE_OF_CONTENTS##"; #this text is replaced with a table of contents for the current h2
    $InsertConstantList = "##INSERT_CONSTANT_LISTING##"; #this text is replaced with a short table of contents
    $ConstantPrefix = "###";
    $Pass1; # result of first pass parsing file.
    $TOCShort; # summary table of contents. (heading 1 only)
    $TOCLong; # detailed table of contents. (all sections)
    $ConstantList;
    $bInLinkDefinition = false;
    $CurrLinkTag;
    %D3DConstant;
    %DefinedLinkDestinations;
    %ExpectedLinkDestinations;
    %DeclaredOutsideLinks;
    %ExpectedOutsideLinks;
    $lastSectionNumber = 0;
    $maxChapters = 1000;
       
    sub Log
    {
        my $output = shift;
        $Pass1 .= $output;
    }
    sub ParseConstantFile
    {
        my ($ConstFile) = @_;
        open(CONSTLIST,$ConstFile) || die("Can't open file $ConstFile");
        while(<CONSTLIST>) {
            if(/^\s*(\w+)\s*=/)
            {
                if(undef!=$D3DConstant{$1})
                {
                    die("$1 defined multiple times!");
                }
            }
            if(/^\s*(\w+)\s*=\s*([+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?(f)?)\s+/)  # float
            {
                $D3DConstant{"$1"} = "$2";
            }
            elsif(/^\s*(\w+)\s*=\s*(0x([a-f]|[A-F]|[0-9])+)\s+/)  # hex
            {
                $D3DConstant{"$1"} = "$2";
            }
            elsif(/^\s*(\w+)\s*=\s*(\w+)\s+/) # word
            {
                if(!exists($D3DConstant{"$2"}))
                {
                    die("$1 being assigned undefined value $2!");
                }
                else
                {
                    $D3DConstant{"$1"} = $D3DConstant{"$2"};   
                }        
            }
            elsif(/^\s*(\w+)\s*=/)
            {
                die("Unrecognized or unsupported assignement of $1 in constant list.");
            }
        }
        close(CONSTLIST);    
    }
    
    ParseConstantFile($::ifile_constants);

    sub GetSectionNumber
    {
        my ($level) = @_;
        local $header = "";
        if( $level == 1 && $HeaderLevel[0] == 0 ) {return $header;}
        
        for ($i=0; $i<$level; $i++)
        {
            if ($i != 0) { $header .= "."; }
            $header .= $HeaderLevel[$i];
        }
        $lastSectionNumber = $header; #unpadded
        if ($level) { $header .= " "; }
        return $header;
    }
    
    sub GetLastSectionNumber
    {
        return $lastSectionNumber;
    }

    sub ComputeConstantList
    {
        @keys = sort keys %D3DConstant;
        $ConstantList .= "<p>Many numbers appearing in this spec link to constants defined ".
              "in the table below.  These constants are made available to applications via D3D headers.</p>";
        $ConstantList .= "<pre><table id=\"ConstantTableListing\" frame=border border=1>\n";
        foreach(@keys)
        {
            $ConstantList .= "<tr><td>$_<td><a id=\"$_\">$D3DConstant{$_}</a></td>\n";
        }   
        $ConstantList .= "</table></pre>";
    }
    
    sub PrintConstantList
    {
        # Assumes ComputeConstantList has been called, initializing $ConstantList
        # This routine replaces all $InsertConstantList with $ConstantList
        my $String = shift;
        $String =~ s/$InsertConstantList/$ConstantList/g;
        return $String;
    }

    sub ComputeTableOfContents
    {
        # First, compute the long table of contents into $TOCLong
        #
        $TOCLong = "\n";
        $TOCLong .= "<A id=\"$tocLong\"></A>\n";
        $DefinedLinkDestinations{$tocLong} = $UseUnlabeledLink;
        $TOCLong .= "<H1>$tocLong</H1><p>(<a href=\"#ShortTableOfContents\">back to top</a>)</p>\n";
        $prevlevel = 1;
        for ($i=1;$i<$HTMLParse::HeaderCount;$i++)
        {
            $level = $HTMLParse::HeaderList[$i][0];
            if ($level < 1) { $prevlevel = $level; next; }
            if ( ($level > $prevlevel) && ($level > 1) )
            {
                for ($j = $prevlevel; $j < $level; $j++) { $TOCLong.= "<DIR>\n"; }
            }
            elsif ($level < $prevlevel)
            {
                for ($j = $level; $j < $prevlevel; $j++) { $TOCLong.= "</DIR>\n"; }
            }
            $TOCLong .= "<LI><A href=\"#".$HTMLParse::HeaderList[$i][1]."\">".$HTMLParse::HeaderList[$i][1]."</A></LI>\n";

            $prevlevel = $level;
        }
        
        # Second, compute the short table of contents into $TOCShort
        #
        $TOCShort = "\n";
        $TOCShort .= "<A id=\"$tocShort\"></A>\n";
        $DefinedLinkDestinations{$tocShort} = $UseUnlabeledLink;
        $TOCShort .= "<H1>$tocShort</H1>\n";
        $CurrChapter = 1;
        for ($i=1;$i<$HTMLParse::HeaderCount;$i++)
        {

            $level = $HTMLParse::HeaderList[$i][0];
            if ($level ne 1) { next; }
            $TOCShort .= "<LI><A href=\"#".$HTMLParse::HeaderList[$i][1]."\">".$HTMLParse::HeaderList[$i][1]."</A></LI>\n";
            $TOCChapter[$CurrChapter] = "<hr><p><a id=\"Chapter".$CurrChapter."Contents\"><b>Chapter Contents</b></a><br><br>(<a href=\"#ShortTableOfContents\">back to top</a>)<br><br>\n";
            $TOCEntriesForCurrentChapter = 0;
            $prevsublevel = 2;
            for ($j=$i+1;$j<$HTMLParse::HeaderCount;$j++)
            {
                $sublevel = $HTMLParse::HeaderList[$j][0];
                if( $sublevel eq 1 ) { last; }  # Stop at the next chapter
                if( $sublevel ge 3 ) { next; }  # Skip 3rd level headings and lower in the chapter TOC

                if ($sublevel > $prevsublevel) 
                {
                    for ($k = $prevsublevel; $k < $sublevel; $k++) { $TOCChapter[$CurrChapter].= "<DIR>\n"; }
                }
                elsif ($sublevel < $prevsublevel)
                {
                    for ($k = $sublevel; $k < $prevsublevel; $k++) { $TOCChapter[$CurrChapter].= "</DIR>\n"; }
                }
                $prevsublevel = $sublevel;

                $TOCChapter[$CurrChapter] .= "<A href=\"#".$HTMLParse::HeaderList[$j][1]."\">".$HTMLParse::HeaderList[$j][1]."</A><br>\n";
                $TOCEntriesForCurrentChapter++;
            }
            for ($k = $prevsublevel; $k > 1; $k--) { $TOCChapter[$CurrChapter].= "</DIR>\n"; }
            $TOCChapter[$CurrChapter] .= "<br></p><hr>\n";
            if( $TOCEntriesForCurrentChapter < 3 )
            {
                $TOCChapter[$CurrChapter] = ""; # Don't bother printing a chapter TOC if there are less than 3 things to list.
            }
            
            $CurrChapter++;
        }
        $TOCShort .= "<br><br>";

        # Third, compute table of contents for each H2 section into $TOCH2
        #
        $CurrChapter = 0;
        $CurrH2 = 1;
        for ($i=1;$i<$HTMLParse::HeaderCount;$i++)
        {

            $level = $HTMLParse::HeaderList[$i][0];
            if ($level eq 1) { $CurrChapter++; $CurrH2 = 1; next; }
            if ($level ne 2) { next; }

            $flatIndex = $CurrH2 * $maxChapters + $CurrChapter;
            $TOCSection[$flatIndex] = "<hr><p><b>Section Contents</b><br><br>(<a href=\"#Chapter".$CurrChapter."Contents\">back to chapter</a>)<br><br>\n";
            $TOCEntriesForCurrentSection = 0;
            $prevsublevel = 3;
            for ($j=$i+1;$j<$HTMLParse::HeaderCount;$j++)
            {
                $sublevel = $HTMLParse::HeaderList[$j][0];
                if( $sublevel le 2 ) { last; }  # Stop at the next section/chapter

                if ($sublevel > $prevsublevel) 
                {
                    for ($k = $prevsublevel; $k < $sublevel; $k++) { $TOCSection[$flatIndex].= "<DIR>\n"; }
                }
                elsif ($sublevel < $prevsublevel)
                {
                    for ($k = $sublevel; $k < $prevsublevel; $k++) { $TOCSection[$flatIndex].= "</DIR>\n"; }
                }
                $prevsublevel = $sublevel;

                $TOCSection[$flatIndex] .= "<A href=\"#".$HTMLParse::HeaderList[$j][1]."\">".$HTMLParse::HeaderList[$j][1]."</A><br>\n";
                $TOCEntriesForCurrentSection++;
            }
            for ($k = $prevsublevel; $k > 2; $k--) { $TOCSection[$flatIndex].= "</DIR>\n"; }
            $TOCSection[$flatIndex] .= "</p>\n";
            if( $TOCEntriesForCurrentSection < 3 )
            {
                $TOCSection[$flatIndex] = ""; # Don't bother printing a chapter TOC if there are less than 3 things to list.
            }
            
            $CurrH2++;
        }
    }

    sub PrintTableOfContents
    {
        # Assumes ComputeTableOfContents has been called, initializing $TOCLong, $TOCShort
        # This routine replaces all $InsertLongTableOfContents with $TOCLong, and $InsertShortTableOfContents with $TOCShort
        # This also replaces $InsertTOCChapter# with a TOC for Chapter #  (the # was auto-inserted in an earlier pass)
        # And $InsertTOCSection#.# with a TOC for Chapter # section # (the #'s were auto-inserted in an earlier pass)
        my $String = shift;
        $String =~ s/$InsertTOCLong/$TOCLong/g;
        $String =~ s/$InsertTOCShort/$TOCShort/g;
        $String =~ s/$InsertTOCChapter(\w+)/$TOCChapter[$1]/g;
        $String =~ s/$InsertTOCSection(\w+)/$TOCSection[$1]/g;
        return $String;
    }


    sub ResolveName
    {
        my($String,$bWithLinkToDefinition) = @_;
        if($bWithLinkToDefinition == 1)
        {
            $String =~ s/$ConstantPrefix(\w+)/(!exists($D3DConstant{$1}))?die "Undefined constant: $1"
            :
            "<a href=\"#$1\" title=\"$1\"><font color=black style=\"text-decoration:none\">".$D3DConstant{$1}."<\/font><\/a>"/ge;
        }
        else
        {
            $String =~ s/$ConstantPrefix(\w+)/(!exists($D3DConstant{$1}))?die "Undefined constant: $1"
            :
            "$D3DConstant{$1}"/ge;
        }
        return $String;
    }
    
    sub ResolveLinkSectionNumbers
    {
        my $String = shift;
        %SectionLabels;
        foreach $linkDest (keys(%DefinedLinkDestinations))
        {
            if( $DefinedLinkDestinations{$linkDest} eq $UseUnlabeledLink ) # e.g. link to table of contents doesn't need section#
            {
                $SectionLabels{$linkDest} = " "; # not using empty string so "broken link" does not hit below
            }
            else
            {
                $SectionLabels{$linkDest} = "<a style=\"color: Gray\"><small><sup>(".$DefinedLinkDestinations{$linkDest}."\)</sup></small></a>";  
            }
        }
        foreach $linkDest (keys(%ExpectedLinkDestinations))
        {
            if( undef eq $SectionLabels{$linkDest} )
            {
                $SectionLabels{$linkDest} = "<a style=\"color: Gray\"><small><sup>\(broken link!\)</sup></small></a>";
            }
        }        
        $String =~ s/([\w\s\(\)\/\-\.\#]*)$LinkSectionTag\[([\w\s\(\)\/\-\.\#]+)\]([\w\s\(\)\/\-\.\#&;]*)<\/([a|A])>/$1$3<\/$4>$SectionLabels{$2}/g;

        return $String;
    }
    
    sub PrintWithNamesResolved
    {
        my $temp = shift;
        $temp = ResolveName($temp,1);
        Log $temp;
    }

    sub ChapterTOC
    {
        my $temp = shift;
        $foo = GetLastSectionNumber;
        $temp =~ s/$InsertTOCChapter/$InsertTOCChapter$foo/g;
        return $temp;
    }

    sub SectionTOC
    {
        my $temp = shift;
        $chap = GetLastSectionNumber;
        $sec = $chap;
        $chap =~ s/(\w+)([.]\w+)*/$1/g;
        $sec =~ s/\w+[.](\w+)([.]\w+)*/$1/g;
        $flatIndex = ($sec * $maxChapters + $chap);
        $temp =~ s/$InsertTOCSection/$InsertTOCSection$flatIndex/g;
        return $temp;       
    }
   
    sub ModHeaderStuff
    {
        my ($level) = @_;
        $InHeader = $level;
        if($level == 1 && $pasttitle == 0) {$pasttitle = 1; return;}
        $HeaderLevel[$level-1]++;
        for ($i=$level;$i<6;$i++) { $HeaderLevel[$i] = 0; }
    }
    
    sub TrackLinks
    {
        my $attr = shift;
        # Store link defined link destinations and expected link definitions in a couple of tables.
        # Later we can make sure there are no broken links.
        foreach $key (keys(%$attr)) {
            if( uc($key) eq "ID" ) 
            {
                if( $attr->{$key} =~ /#?(.*)/ )
                {
                    if(undef!=$DefinedLinkDestinations{$1})
                    {
                        $MessageCount++;
                        $Messages .= "(".$MessageCount.") Error: Link target \"$1\" defined multiple times!\n\n";
                    }
                    if( $InHeader )
                    {
                        GetSectionNumber( $InHeader ); # compute section number
                    } # else we are in the body of a section
                    $DefinedLinkDestinations{$1} = GetLastSectionNumber; # unpadded section number
                }
            }
            else
            {
                if( uc($key) eq "HREF" )
                {
                    if( $attr->{$key} =~ /^\#(.*)/ ) #Is the link preceded by the '#' character?
                    {
                        if( undef eq $ExpectedLinkDestinations{$1} )
                        {
                            $ExpectedLinkDestinations{$1} = 1;
                        }
                    }
                    else
                    {
                        $DefinedLinkDestinations{$attr->{$key}} = "outside link";
                        $ExpectedOutsideLinkDeclarations{$attr->{$key}} = 1;                        
                    }                                       
                }
            }
        }
    }
    
    sub ValidateLinks
    {
        foreach $linkDest (keys(%ExpectedLinkDestinations))
        {
            if( undef eq $DefinedLinkDestinations{$linkDest} )
            {
                $MessageCount++;
                $Messages .= "(".$MessageCount.") Error: id=\"$linkDest\" expected as link target, but not defined anywhere.\n\n";
            }
        }
        foreach $linkDecl(keys(%ExpectedOutsideLinkDeclarations))
        {
            if( undef eq $DeclaredOutsideLinks{$linkDecl} )
            {
                $MessageCount++;
                $Messages .= "(".$MessageCount.") Info: The link \"$linkDecl\" is assumed to be a reference ".
                       "outside the document, either a website or accompanying file. ".
                       "If so, note that this build does not verify its integrity.  However, if the author intended ".
                       "for the link to be internal to the document, the # prefix is missing.  To mute this message ".
                       "for this link, declare the link as external by inserting: ##OUTSIDE_LINK## in the visible link label (it will get stripped).\n\n";
            }
        }
    }
        
    sub start
    {
        my($self, $tagname, $attr, $attrseq, $origtext) = @_;
        
        if ( $in_int && $::no_int ) { return; }
        if ( $in_api && $::in_api ) { return; }
        if ( $in_ddi && $::no_ddi ) { return; }
        if ( $in_rem && $::no_rem ) { return; }
        if ( $in_del10To11 && $::no_del10To11 ) { return; }
        if ( uc($tagname) eq "H1" ) { ModHeaderStuff(1); TrackLinks($attr); if ( uc($origtext) ne "<H1>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }
        if ( uc($tagname) eq "H2" ) { ModHeaderStuff(2); TrackLinks($attr); if ( uc($origtext) ne "<H2>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }
        if ( uc($tagname) eq "H3" ) { ModHeaderStuff(3); TrackLinks($attr); if ( uc($origtext) ne "<H3>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }
        if ( uc($tagname) eq "H4" ) { ModHeaderStuff(4); TrackLinks($attr); if ( uc($origtext) ne "<H4>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }
        if ( uc($tagname) eq "H5" ) { ModHeaderStuff(5); TrackLinks($attr); if ( uc($origtext) ne "<H5>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }
        if ( uc($tagname) eq "H6" ) { ModHeaderStuff(6); TrackLinks($attr); if ( uc($origtext) ne "<H6>" ) {PrintWithNamesResolved "$origtext</$tagname>";} return; }

        TrackLinks($attr); # must be after calls to "ModHeaderStuff" above

        foreach $key (keys(%$attr)) 
        {
            if( uc($key) eq "HREF" ) 
            {
                $bInLinkDefinition = true;
                if( $attr->{$key} =~ /^#(.*)/ )
                {
                    $CurrLinkTag = $1;
                }
                else 
                {
                    $CurrLinkTag = $attr->{$key};
                }
                break;
            }
        }

        PrintWithNamesResolved $origtext;
    }
    sub end
    {
        my($self, $tagname, $origtext) = @_;
        if ( $in_int && $::no_int ) { return; }
        if ( $in_api && $::in_api ) { return; }
        if ( $in_ddi && $::no_ddi ) { return; }
        if ( $in_rem && $::no_rem ) { return; }
        if ( $in_del10To11 && $::no_del10To11 ) { return; }
        if ($InHeader)
        {
            $NewHeader = GetSectionNumber($InHeader).$Header;
            # strip trailing whitespace - it confuses href tags
            ($NewHeader) = split /\s+$/, $NewHeader;
            $ResolvedNewHeader = ResolveName($NewHeader,0);
            $HeaderList[$HeaderCount][0] = $InHeader;
            $HeaderList[$HeaderCount][1] = $ResolvedNewHeader;
            $HeaderCount++;
            $InHeader = 0;
            $Header = "";

            PrintWithNamesResolved "<A id=\"".$ResolvedNewHeader."\"></A>\n";
            PrintWithNamesResolved "<".uc($tagname).">";
            PrintWithNamesResolved $NewHeader;
            PrintWithNamesResolved "</".uc($tagname).">";
        }
        else
        {
            if( uc($tagname) eq "BODY" )
            {
                ComputeTableOfContents; 
                ComputeConstantList; 
                ValidateLinks;
                $Pass2 = PrintConstantList($Pass1);
                $Pass3 = ResolveLinkSectionNumbers($Pass2);
                $Pass4 = PrintTableOfContents($Pass3);
                print $Pass4;
                if( "" ne $Messages )
                {
                    $Messages .= $MessageCount." potential issues found. \n";
                    die($Messages)
                }
            }
            PrintWithNamesResolved $origtext;
        }
    }
    sub text
    {
        my($self, $origtext, $is_cdata) = @_;
        if ( $in_int && $::no_int ) { return; }
        if ( $in_api && $::in_api ) { return; }
        if ( $in_ddi && $::no_ddi ) { return; }
        if ( $in_rem && $::no_rem ) { return; }
        if ( $in_del10To11 && $::no_del10To11 ) { return; }
        if ($InHeader) { $Header .= $origtext; }
        else
        {
            if( $bInLinkDefinition eq true )
            {
                if( $origtext =~ /(.*)(\s*)$UseUnlabeledLink(\s*)(.*)/ )
                {
                    PrintWithNamesResolved $1.$4; # don't label this link with section number, and skip the tag telling us that.
                }
                elsif( $origtext =~ /(.*)(\s*)$OutsideLink(\s*)(.*)/ )
                {
                    $DeclaredOutsideLinks{$CurrLinkTag} = 1; # remember that the outside link has been declared
                    PrintWithNamesResolved $1.$4.$LinkSectionTag."\[".$CurrLinkTag."\]"; #strip $OutsideLink
                }
                else
                {
                    PrintWithNamesResolved $origtext.$LinkSectionTag."\[".$CurrLinkTag."\]";
                }
                $bInLinkDefinition = false;
            }
            else           
            { 
	        $origtext = ChapterTOC SectionTOC $origtext;

                PrintWithNamesResolved $origtext; 
            }
        }
    }
    sub comment
    {
        my($self, $origtext) = @_;
        if ( uc($origtext) eq "INT" )  { $in_int = 1; if(!$::no_int && !$InHeader) {Log "<DIV class=boxed style=\"background-color: pink\"><small><i>[MS internal build]</i></small><br>"} return; }
        if ( uc($origtext) eq "/INT" ) { $in_int = 0; if(!$::no_int && !$InHeader) {Log "</DIV>"} return; }
        if ( uc($origtext) eq "DDI" )  { $in_ddi = 1; if(!$::no_int && !$InHeader) {Log "<DIV class=boxed style=\"background-color: lightgreen\"><small><i>[DDI build]</i></small><br>"} return; }
        if ( uc($origtext) eq "/DDI" ) { $in_ddi = 0; if(!$::no_int && !$InHeader) {Log "</DIV>"} return; }
        if ( uc($origtext) eq "API" )  { $in_api = 1; if(!$::no_int && !$InHeader) {Log "<DIV class=boxed style=\"background-color: orange\"><small><i>[API build]</i></small><br>"} return; }
        if ( uc($origtext) eq "/API" ) { $in_api = 0; if(!$::no_int && !$InHeader) {Log "</DIV>"} return; }
        if ( uc($origtext) eq "REM" )  { $in_rem = 1; if(!$::no_int && !$InHeader) {Log "<DIV class=boxed style=\"background-color: lightblue\"><small><i>[Remark]</i></small><br>"}
                                                      elsif(!$InHeader) {Log "<DIV class=boxed style=\"background-color: lightblue\">"}
                                                      return; }
        if ( uc($origtext) eq "/REM" ) { $in_rem = 0; if(!$InHeader) {Log "</DIV>"} return; }
        if ( uc($origtext) eq "DEL10TO11" )  { $in_del10To11 = 1; if(!$::no_int && !$::no_del10To11 && !$InHeader) {Log "<DIV class=boxed style=\"background-color: yellow\"><small><i>[delta: D3D10-&gt;D3D11.1]</i></small><br>"}
                                                      elsif(!$InHeader) {Log "<DIV class=boxed style=\"background-color: yellow\">"}
                                                      return; }
        if ( uc($origtext) eq "/DEL10TO11" ) { $in_del10To11 = 0; if(!$InHeader) {Log "</DIV>"} return; }
        if ($InHeader) { $Header .= $origtext; }
        else           { PrintWithNamesResolved "<!--$origtext-->"; }
    }
    sub declaration
    {
        my($self, $origtext) = @_;
        PrintWithNamesResolved "<!$origtext>";
    }
}


# Open and initialize the files
open(INFILE, "$ifile") || die "Unable to open $ifile for reading\n";

my $p = HTMLParse->new;
$p->parse_file(*INFILE);

#-----------------------------------------------------------------------------
# END
#-----------------------------------------------------------------------------

