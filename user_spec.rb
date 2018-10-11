require 'airborne'
require 'json'

describe 'users api endpoint' do

  let(:endpt){'http://actenum-qa-test.us-west-2.elasticbeanstalk.com/api/users'}

  def get_users
    get endpt
    json_body
  end

  # reset the users collection before each test
  before(:each) do
    post "#{endpt}/reset"
  end

  after(:each) do |example|
    if example.exception
      puts 'response info: '
      begin
        puts json_body
        puts response.code
      rescue
        puts body
        puts response.code
      rescue
        puts response.code
      rescue
        puts 'no response'
      end
    end
  end

  it 'should get users' do
    users = get_users
    expect(users.size).to be > 0
    user = users[0]
    expect(user).to include(:id, :firstName, :lastName, :email)
  end

  it 'should get specific user' do
    user = get_users[0]
    puts user[:id]

    get "#{endpt}/#{user[:id]}"
    expect(json_body).to eq(user)
    # BUG: the type for lastLogin is different
    # BUG: rename isactive to isActive?
  end

  it 'ignore additional url parameters' do
    user = get_users[0]
    puts user[:id]

    get "#{endpt}/#{user[:id]}?a=234325"
    expect(json_body).to eq(user)
  end

  it 'should get nonexisting user' do
    get "#{endpt}/zxcvzxcv"
    expect(response.code).to be 404

    get "#{endpt}/_"
    expect(response.code).to be 404

    # BUG: the code should not be 405 - there is no mismatch of http method
  end

  ## POST endpoint

  it 'add user with required fields' do
    post endpt, {firstName: 'mickey', lastName: 'mouse', email: 'mickey.mouse@disney.mail'}

    # find the added user
    users = get_users
    expect(users).to include(a_hash_including(firstName: 'mickey', lastName: 'mouse'))
    matches = users.find_all { |user| user >= {firstName: 'mickey', lastName: 'mouse'} }
    expect(matches.size).to be(1), 'found added user via first and last name more than once'

    # verify details on the added user
    match = matches[0]
    expected = {firstName: 'mickey', lastName: 'mouse', email: 'mickey.mouse@disney.mail'}
    expect(match).to be >= (expected), 'user does not have matching email'
    # check the generated fields are present
    expect(match).to include(:lastLogin, :created, :id, :isactive)
    # BUG: created date format is different...
  end

  it 'add user without required fields' do
    post endpt, {apple: 'orange'}
    # BUG: improvement: should tell user what to add
    expect(response.code).to be(400), 'unexpected response code'
  end

  it 'add user with only first name' do
    post endpt, {firstName: 'mickey', email: 'mickey.mouse@disney.mail'}
    expect(response.code).to eq(400)
    # BUG: 500 error
  end

  it 'add user with same email as existing user' do
    user = get_users[0]
    email = user[:email]

    user = {firstName: 'steve', lastName: 'jobs', email: email}
    puts user

    post endpt, user

    users = get_users
    # expect(200..209).not_to include(response.code)
    matches = users.find_all { |u| u[:email] == email }
    expect(matches.size).to be <= (1), 'found more than one user with same email'
    # BUG: uniqueness of email is not checcked, duplicate email user gets added anyway
  end

  it 'should handle adding user with same name as existing user' do
    orig_user = get_users[0]
    puts orig_user
    new_user = {firstName: orig_user[:firstName], lastName: orig_user[:lastName], email: 'new@email.com'}

    post endpt, new_user

    users = get_users
    match = users.find { |u| u[:id] == orig_user[:id] }
    expect(match[:email]).not_to eq(new_user[:email]), 'user with original id has different email'
    expect(match[:created]).to eq(orig_user[:created]), 'user with original id has different created date'

    # BUG: it overrides the user with the same name (therefore the same id)
  end

  ## PUT endpoint

  it 'should update user with new name' do
    user = get_users[0]
    user = {id: user[:id], email: user[:email], firstName: 'donald', lastName: 'duck'}
    puts user

    put "#{endpt}/#{user[:id]}", user
    expect(response.code).to be (201)

    # find the updated user
    users = get_users
    expect(users).to include(a_hash_including(firstName: 'donald', lastName: 'duck'))
    match = users.find { |user| user >= {firstName: 'donald', lastName: 'duck'} }
    expect(match[:id]).to eq(user[:id]), 'did not modify correct user?'
  end

  it 'should update user with new email' do
    user = get_users[0]
    user = {id: user[:id], email: 'donald.duck@disney.mail', firstName: user[:firstName], lastName: user[:lastName]}
    puts user

    put "#{endpt}/#{user[:id]}", user
    expect(response.code).to be (201)

    # find the updated user
    users = get_users
    expect(users).to include(a_hash_including(email: 'donald.duck@disney.mail'))
    match = users.find { |user| user >= {email: 'donald.duck@disney.mail'} }
    expect(match[:id]).to eq(user[:id]), 'did not modify correct user?'
  end

  it 'should reject update using existing email of another user' do
    users = get_users
    user_one = users[0]
    user_two = users[1]
    new_user = {id: user_one[:id], email: user_two[:email], firstName: user_one[:firstName], lastName: user_one[:lastName]}
    puts new_user

    put "#{endpt}/#{user_one[:id]}", new_user
    # expect(response.code).to be (400), 'should not allow update with email of another user'

    users = get_users

    matches = users.find { |u| u[:email] == user_two[:email] }
    expect(matches.size).to eq(1), 'duplicate emails found'

    match = users.find { |u| u[:id] == user_one[:id] }
    expect(match[:email]).not_to eq(user_two[:email]), 'user has same email as another'
  end

  it 'should reject update user without required fields' do
    user = get_users[0]

    put "#{endpt}/#{user[:id]}", {id: user[:id]}
    # expect(response.code).not_to be (201)

    users = get_users

    match = users.find { |u| u[:id] == user[:id] }
    expect(match).to include(:id, :firstName, :lastName, :email)

    # BUG: the update is accepted and now the user doesn't have the other required fields - first/last name and email
  end

  it 'update user without specifying id in url' do
    user = get_users[0]
    user.delete(:id)
    puts user

    put endpt, user
    expect(response.code).to be (404)
  end

  it 'update user without id in body' do
    user = get_users[0]
    user.delete(:id)
    puts user

    put "#{endpt}/#{user[:id]}", user
    expect(response.code).to be (404)
  end

  it 'update nonexisting user' do
    user = get_users[0]

    put "#{endpt}/apple", {id: 'apple'}
    expect(response.code).to be (404)
  end

end
