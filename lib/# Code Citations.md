# Code Citations

## License: MIT
Source: https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

This project includes code adapted from the CS308-Project repository for password field implementation with visibility toggle functionality.

```dart
TextFormField(
  obscureText: _obscurePassword,
  decoration: InputDecoration(
    labelText: 'Password',
    suffixIcon: IconButton(
      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
      onPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    ),
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  },
)
```

Used under MIT License terms for educational and development purposes.
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                label
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Passwor
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffix
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon:
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value)
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (
```


## License: MIT
https://github.com/SerhanTelatar/CS308-Project/blob/4eca88b2b89d97e49fe6e2b574a91275b0878532/mobile_app/lib/routes/register_page.dart

```
,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value
```

