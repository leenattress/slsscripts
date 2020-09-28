#!/bin/bash
# AWS script builder for serverless interaction

pause() {
    read -p "Press [Enter] key to continue..." fackEnterKey
}

# Set AWS Profile
profile() {
    echo "Which AWS Profile should we use?"
    read aws_profile
    echo "The current profile is $aws_profile"
}

# Set my stack
stack() {
    echo "Which Stack Should We Use?"
    read sls_stack
    echo "The current stack is $sls_stack"
}

# Set my mfa arn
mfa() {
    echo "What is your MFA ARN?"
    read mfa_arn
    echo "The MFA ARN is $mfa_arn"
}

build() {
    if [ -d "$HOME/bin" ]; then
        echo "✅ ~/bin exists"
    else
        # Create our bin folder
        echo "📁 Creating ~/bin for our scripts"
        mkdir $HOME/bin

        # Add bin folder to path
        PATH=${PATH}:$HOME/bin
        export PATH
    fi

    if [ ${mfa_arn} ]; then

        # Build MFA script
        ESCAPED_REPLACE_MFA=$(printf '%s\n' "$mfa_arn" | sed -e 's/[\/&]/\\&/g')
        cp slsmfa.template temp1.txt
        sed "s/AWSPROFILE/$aws_profile/" temp1.txt >temp2.txt
        sed "s/IAMARN/$ESCAPED_REPLACE_MFA/" temp2.txt >$HOME/bin/slsmfa
        echo "✅ Wrote slsmfa script"
        rm temp1.txt
        rm temp2.txt
        chmod u+x $HOME/bin/slsmfa

        # the profile for everything else is now 'mfa'
        aws_profile=mfa

    fi

    # Build info script
    cat <<EOT >$HOME/bin/slsinfo
#!/bin/bash
sls info --infraStackName $sls_stack --aws-profile $aws_profile
EOT
    chmod u+x $HOME/bin/slsinfo
    echo "✅ Wrote slsinfo script"

    # Build deploy script
    cat <<EOT >$HOME/bin/slsdeploy
#!/bin/bash
sls deploy --infraStackName $sls_stack --aws-profile $aws_profile
EOT
    chmod u+x $HOME/bin/slsdeploy
    echo "✅ Wrote slsdeploy script"


    # Build offline script
    cat <<EOT >$HOME/bin/slsoffline
#!/bin/bash
sls offline --infraStackName $sls_stack --aws-profile $aws_profile
EOT
    chmod u+x $HOME/bin/slsoffline
    echo "✅ Wrote slsoffline script"
    
    # List Buckets script
    # backtick='`'
    # cat <<EOT > $HOME/bin/slsbuckets
    # #!/bin/bash
    # aws cloudformation list-stack-resources --profile $aws_profile --stack-name $sls_stack  --output yaml --query 'StackResourceSummaries[?ResourceType==${backtick}AWS::Lambda::Function${backtick}].PhysicalResourceId'
    # EOT
    # chmod u+x $HOME/bin/slsbuckets
    # echo "✅ Wrote slsbuckets script"

    pause
    #exit 0
}

ReadINISections() {
    local filename="$1"
    gawk '{ if ($1 ~ /^\[/) section=tolower(gensub(/\[(.+)\]/,"\\1",1,$1)); configuration[section]=1 } END {for (key in configuration) { print key} }' ${filename}
}

profiles() {
    echo
    echo "AWS Profiles:"
    echo
    INI_FILE=~/.aws/credentials

    sections="$(ReadINISections $INI_FILE)"
    for section in $sections; do
        echo "  ${section}"
    done
    echo

    pause
}

helpme() {
    echo ""
    echo "       ---===###   HELP   ###===---         "
    echo ""
    echo "This script is designed to make the task of"
    echo "setting up your MFA key for AWS, and providing"
    echo "small helper scripts to make working with"
    echo "serverless simpler and more forgiving."
    echo ""
    echo "In the main menu, provide your local profile"
    echo "name (or see a list so you can copy/paste)."
    echo ""
    echo "Add the name of your serverless stack."
    echo ""
    echo "Optionally add your arn:aws:iam::xxxxxxxxx"
    echo ""
    echo "What this script does is create pre formatted"
    echo "aws and sls bash scripts and saves them into"
    echo "your ~/bin folder."
    echo ""
    echo "After you have generated your scripts, restart"
    echo "your terminal."
    echo ""
    echo "You can now get your MFA working like this:"
    echo "slsmfa 123456"
    echo "(where the numbers are from your authenticator)"
    echo ""
    echo "You can now enter a serverless framework"
    echo "folder and run:"
    echo ""
    echo "slsinfo or slsdeploy"
    echo ""
    echo "Your details are saved in the scripts."
    echo "Thats all, happy coding!"
    echo ""
    echo "- Lee"
    pause
}

# function to display menus
show_menus() {
    clear
    echo
    echo " ~~~~~~~~~~~~~~~~~~~~~~~"
    echo "  S L S - S C R I P T S "
    echo " ~~~~~~~~~~~~~~~~~~~~~~~"
    echo
    if [ -z ${aws_profile} ]; then
        echo " 1. Choose AWS Profile"
    else
        echo " 1. Change AWS Profile ($aws_profile)"
    fi

    if [ -z ${sls_stack} ]; then
        echo " 2. Choose Stack Name"
    else
        echo " 2. Change Stack Name ($sls_stack)"
    fi

    if [ -z ${mfa_arn} ]; then
        echo " 3. Choose MFA device ARN"
    else
        echo " 3. Change MFA device ARN ($mfa_arn)"
    fi

    echo " 4. Build Scripts"
    echo " 5. List Local Profiles"
    echo " 6. Help"
    echo " 0. Exit without Building"
    echo
}
# read input from the keyboard and take a action
# Exit when user the user select exit form the menu option.
read_options() {
    local choice
    read -p " Enter choice [ 0 - 6 ] " choice
    case $choice in
    1) profile ;;
    2) stack ;;
    3) mfa ;;
    4) build ;;
    5) profiles ;;
    6) helpme ;;
    0) exit 0 ;;
    esac
}

# ----------------------------------------------
# Uncomment to stop CTRL+C, CTRL+Z and quit signals
# ----------------------------------------------
# trap '' SIGINT SIGQUIT SIGTSTP

# -----------------------------------
# Main logic - infinite loop
# ------------------------------------
while true; do
    show_menus
    read_options
done
