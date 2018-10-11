require 'airborne'
require 'json'

describe 'users api endpoint' do

  let(:endpt){'http://actenum-qa-test.us-west-2.elasticbeanstalk.com/api/users'}

  def get_users
    get endpt
    json_body
  end

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
    puts users
    user = users[0]
    expect(user).to include(:id, :firstName, :lastName, :email)
  end

  it 'should get specific user' do
    user = get_users[0]
    puts user[:id]

    get "#{endpt}/#{user[:id]}"
    expect(json_body).to eq(user)
    # BUG: the type for lastLogin is different
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
    expect(matches.size).to be(1), 'could find added user via first and last name'

    # verify details on the added user
    match = matches[0]
    expected = {firstName: 'mickey', lastName: 'mouse', email: 'mickey.mouse@disney.mail'}
    expect(match).to be >= (expected), 'user does not have matching email'
    # check the generated fields are present
    expect(match).to include(:lastLogin, :created, :id, :isactive)
    # BUG: rename isactive to isActive?
    # BUG: last login should be integer...
  end

  it 'add user without required fields' do
    post endpt, {apple: 'orange'}
    # BUG: improvement: should tell user what to add
    puts body
    expect(response.code).to be(400), 'unexpected response code'
  end

  it 'add user with same email as another user' do

  end

  it 'should reject adding user with same name' do

  end

  ## PUT endpoint

  it 'should update user with required fields' do
    user = get_users[0]
    puts user[:id]

    user[:firstName] = 'donald'
    user[:lastName] = 'duck'

    put endpt, user
    expect(response.code).to be(201)

    # check the updated fields
  end

  it 'update user without required fields' do
    user = get_users[0]
    puts user[:id]

    put endpt, {id: user[:id]}
    expect(response.code).to be(404)
  end

  it 'update user without id' do
    user = get_users[0]
    user.delete(:id)
    puts user

    put endpt, user
    expect(response.code).to be(400)
  end

  it 'update nonexisting user' do
    user = get_users[0]

    put endpt, {id: 'apple'}
    expect(response.code).to be(400)
  end

end
